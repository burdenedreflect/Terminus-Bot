#
# Terminus-Bot: An IRC bot to solve all of the problems with IRC bots.
#
# Copyright (C) 2010-2012 Kyle Johnson <kyle@vacantminded.com>, Alex Iadicicco
# (http://terminus-bot.net/)
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#

CHANLOG_DIR = "var/terminus-bot/chanlog/"

def initialize
  register_script "Logs channel activity to disk."

  register_event :PRIVMSG, :on_privmsg
  register_event :raw_out, :on_raw_out

  register_event :NOTICE,  :on_notice
  register_event :TOPIC,   :on_topic

  register_event :KICK,    :on_kick
  register_event :PART,    :on_part
  register_event :JOIN,    :on_join
  register_event :QUIT,    :on_quit

  register_event :NICK,    :on_nick
  register_event :MODE,    :on_mode

  register_event :em_started, :on_em_started


  unless Dir.exists? CHANLOG_DIR
    Dir.mkdir CHANLOG_DIR
  end

  @loggers = Hash.new
end

def on_em_started
  # If we're being loaded on a bot that's already running, we're not going
  # to see the JOIN events we need to start the loggers. So we have to do
  # it the hard way, just in case.

  Bot::Connections.each do |name, connection|
    connection.channels.each_key do |channel|
      new_logger connection.name, channel
    end
  end
end

def die
  # Close all our loggers.
  @loggers.each_value do |c|
    c.each_value do |l|
      l.close
    end
  end
end


# Logger stuff

def log_msg network, channel, type, speaker, str = ""
  $log.debug("chanlog.log_msg") { "#{network} #{channel} #{type} #{speaker} #{str}" }

  new_logger network, channel

  @loggers[network][channel].info(type) { "#{speaker}\t#{str}" }
end

def new_logger network, channel
  @loggers[network] ||= Hash.new

  if @loggers[network].has_key? channel
    # We already have a logger for this channel.
    return
  end

  @loggers[network][channel] = Logger.new "#{CHANLOG_DIR}#{network}.#{channel}.log"

  @loggers[network][channel].formatter = proc do |severity, datetime, progname, msg|
    "#{datetime}\t#{progname}\t#{msg}\n"
  end

  @loggers[network][channel].datetime_format = "%Y-%m-%d %H:%M:%S %z"

  $log.debug("chanlog.new_logger") { "#{network} #{channel}" }
end

def close_logger network, channel
  @loggers[network][channel].close
  @loggers[network].delete channel

  $log.debug("chanlog.close_logger") { "#{network} #{channel}" }
end


# Event callbacks

def on_raw_out msg
  return unless msg.type == :PRIVMSG

  on_privmsg msg
end

def on_privmsg msg
  return if msg.private?

  if msg.text =~ /\01ACTION (.+)\01/
    log_msg msg.connection.name, msg.destination, "ACTION", msg.nick, msg.strip($1)
  elsif not msg.text =~ /\01.+\01/
    log_msg msg.connection.name, msg.destination, "PRIVMSG", msg.nick, msg.stripped
  end
end

def on_notice msg
  return if msg.private?

  unless msg.text =~ /\01.+\01/
    log_msg msg.connection.name, msg.destination, "NOTICE", msg.nick, msg.stripped
  end
end

def on_kick msg
  log_msg msg.connection.name, msg.destination, "KICK", msg.nick, "#{msg.raw_arr[3]} (#{msg.stripped})"

  # If we're the ones kicked, close the logger.
  if msg.raw_arr[3] == msg.connection.nick
    close_logger msg.connection.name, msg.destination
  end
end

def on_part msg
  log_msg msg.connection.name, msg.destination, "PART", msg.nick, msg.stripped

  # We parted, apparently. Stop logging.
  if msg.me?
    close_logger(msg.connection.name, msg.destination)
  end
end

def on_join msg
  # We joined. Better get ready to log!
  if msg.me?
    new_logger msg.connection.name, msg.destination
  end

  log_msg msg.connection.name, msg.destination, "JOIN", msg.nick
end

def on_quit msg
  msg.connection.channels.each_value do |chan|
    if chan.get_user msg.nick
      log_msg msg.connection.name, chan.name, "QUIT", msg.nick, msg.stripped
    end
  end
end

def on_topic msg
  log_msg msg.connection.name, msg.destination, "TOPIC", msg.nick, msg.stripped
end

def on_nick msg
  msg.connection.channels.each_value do |chan|
    if chan.get_user msg.nick or chan.get_user msg.text
      log_msg msg.connection.name, chan.name, "NICK", msg.nick, msg.text
    end
  end
end

def on_mode msg
  log_msg msg.connection.name, msg.destination, "MODE", msg.nick, msg.raw_arr[3..msg.raw_arr.length-1].join(" ")
end

