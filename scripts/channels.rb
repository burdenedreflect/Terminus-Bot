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

def initialize
  register_script "Manage the list of channels the bot occupies."

  register_command "joinchans", :cmd_joinchans, 0,  10, nil, "Force the join channels event."
  register_command "join",      :cmd_join,      1,  5,  nil, "Join a channel with optional key."
  register_command "part",      :cmd_part,      1,  5,  nil, "Part a channel."
  register_command "cycle",     :cmd_cycle,     1,  5,  nil, "Part and then join a channel."

  register_event :"001", :join_channels
  register_event :JOIN,  :on_join
  register_event :PING,  :leave_channels
  register_event :PING,  :join_channels

  @canonized = Hash.new false

  # TODO: All channel names in here need to use proper casemapping.
  # TODO: Handle 405?
end

def join_channels msg
  chans, keys = [], []
  channels = get_data msg.connection.name, Hash.new

  channels.each_pair do |channel, key|
    next if msg.connection.channels.has_key? channel

    chans << channel
    keys << (key.empty? ? "x" : key)

    # TODO: determine a sane maximum for this
    if chans.length == 4
      msg.raw "JOIN #{chans.join(",")} #{keys.join(",")}"
      chans.clear
      keys.clear
    end
  end

  msg.raw "JOIN #{chans.join(",")} #{keys.join(",")}" unless chans.empty?
end

def on_join msg
  # Are we enabled?
  return unless get_config "antiforce", false

  # Are we the ones joining?
  return unless msg.me?

  channels = get_data msg.connection.name, Hash.new
  channel  = msg.connection.canonize msg.destination

  # Are we configured to be in this channel?
  return if channels.has_key? channel
 
  $log.debug("channels.on_join") { "Parting channel #{msg.destination} since we are not configured to be in it." }

  # It doesn't look like we should be here. Part!
  msg.raw "PART #{msg.destination} :I am not configured to be in this channel."
end

def leave_channels msg
  channels = get_data msg.connection.name, Hash.new

  msg.connection.channels.each_key do |chan|
    next if channels.has_key? chan

    msg.raw "PART #{chan} :I am not configured to be in this channel."
  end
end

def cmd_joinchans msg, params
  join_channels  msg
  msg.reply "Done"
end

def cmd_join msg, params
  arr = params[0].split /\s+/, 2

  name = msg.connection.canonize arr[0]
  key = arr.length == 2 ? arr[1] : ""

  # TODO: Use CHANTYPES
  unless name.start_with? "#" or name.start_with? "&"
    msg.reply "That does not look like a channel name."
    return
  end

  channels = get_data msg.connection.name, Hash.new

  channels[name] = key
  store_data msg.connection.name, channels

  msg.raw "JOIN #{name} #{key}"
  msg.reply "I have joined #{name}"
end

def cmd_part msg, params
  name = msg.connection.canonize params[0]
  channels = get_data msg.connection.name, Hash.new

  unless channels.has_key? name
    msg.reply "I am not configured to join that channel, but I'll dispatch a PART for it just in case."
    msg.raw "PART #{name} :Leaving channel at request of #{msg.nick}"
    return
  end

  results = channels[name]
  channels.delete name

  store_data msg.connection.name, channels

  msg.raw "PART #{name} :Leaving channel at request of #{msg.nick}"
  msg.reply "I have left #{name}"
end

def cmd_cycle msg, params
  channels = get_data msg.connection.name, Hash.new

  return unless channels.has_key? params[0].downcase
  
  msg.raw "PART #{params[0]} :Be right back!"
  msg.raw "JOIN #{params[0]}"
end

