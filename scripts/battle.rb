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
  register_script "IRC role-play battle tracker."

  register_command "battle", :cmd_battle, 1, 0, :half_op, "Start, stop, or reset the battle in the current channel. Parameters: START|STOP|RESTART"
  register_command "health", :cmd_health, 0, 0, nil,      "View the health of all active players in this channel."
  register_command "heal",   :cmd_heal,   1, 0, :half_op, "Heal players to maximum health. If no nick is given, all players are reset. Parameters: nick"

  register_event :PRIVMSG, :on_privmsg
  
  @active = Hash.new
end

def cmd_battle msg, params
  if msg.private?
    msg.reply "You may only battle in channels."
    return
  end

  case params[0].upcase

  when "START"

    if @active.has_key? msg.destination_canon
      msg.reply "There is already an active battle in \02#{msg.destination}\02"
      return
    end

    start_battle msg

  when "STOP"

    unless @active.has_key? msg.destination_canon
      msg.reply "There is no active battle in \02#{msg.destination}\02"
      return
    end

    @active.delete msg.destination_canon

    msg.reply "The battle in \02#{msg.destination}\02 has been ended by \02#{msg.nick}\02", false

  when "RESTART"

    unless @active.has_key? msg.destination_canon
      msg.reply "There is no active battle in \02#{msg.destination}\02"
      return
    end

    @active[msg.destination_canon] = Hash.new

    msg.reply "The battle in \02#{msg.destination}\02 has been restarted by \02#{msg.nick}\02.", false

  else

    msg.reply "Unknown action. Parameters: START|STOP|RESTART"

  end
end


def start_battle msg
  @active[msg.destination_canon] = Hash.new

  msg.reply "\02#{msg.nick}\02 has started a battle!", false
  msg.reply "To attack other players, use \02/me attacks TARGET with ITEM\02", false
  msg.reply "You may check the health of active players by using the \02HEALTH\02 command.", false
end


def get_health msg, target
  return @active[msg.destination_canon][target] if @active[msg.destination_canon].include? target

  return get_config :start_health, 100
end


def set_health msg, target, health
  @active[msg.destination_canon][target] = health
end


def heal_player msg, target
  set_health msg, target, get_config(:start_health, 100)
end


def attack_player msg, target, weapon
  original = target
  target = msg.connection.canonize target

  unless msg.connection.channels[msg.destination_canon].users.has_key? target
    msg.reply "There is no such user in the channel."
    return
  end

  current = get_health msg, target
  my_health = get_health msg, msg.connection.canonize(msg.nick)

  if my_health == 0
    msg.reply "You cannot attack while dead."
    return
  end

  if current == 0
    msg.reply "#{original} is already dead.", false
    return
  end

  damage = get_config(:min_dmg, 5).to_i + rand(get_config(:max_dmg, 25).to_i - get_config(:min_dmg, 5).to_i)
                                                           
  if rand(100) <= get_config(:absorb, 5).to_i
    damage = damage * -1
  end

  new = current - damage
  new = 0 if new < 0

  if rand(100) < get_config(:miss, 10).to_i
    msg.reply "#{original} dodges #{msg.nick}'s #{weapon}.", false
    return
  end

  set_health msg, target, new

  if damage > 0
    msg.reply "#{msg.nick}'s #{weapon} hits #{original} for \02#{damage} damage\02.", false

    if new == 0
      msg.reply "#{original} has been defeated!", false

    else 
      msg.reply "#{original} has \02#{new}\02 health remaining.", false

    end

    return
  end

  if damage < 0
    msg.reply "#{original} absorbs the hit and \02gains #{(damage*-1)} health!\2", false
    msg.reply "#{original} has \02#{new}\02 health remaining.", false

    return
  end

  msg.reply "#{msg.nick}'s #{weapon} is completely ineffective.", false

end

def cmd_health msg, params

  unless @active.has_key? msg.destination_canon
    msg.reply "There is no active battle in \02#{msg.destination}\02"
    return
  end

  msg.send_notice msg.nick, "There are currently \02#{@active[msg.destination_canon].keys.length}\02 players in \02#{msg.destination}\02:"

  @active[msg.destination_canon].each do |player, health|
    msg.send_notice msg.nick, "\02#{sprintf("%31.31s", player)}\02 #{health} HP"
  end

  msg.send_notice msg.nick, "End of list."

end

def cmd_heal msg, params

  unless @active.has_key? msg.destination_canon
    msg.reply "There is no active battle in \02#{msg.destination}\02"
    return
  end

  target = msg.connection.canonize params[0]

  unless @active[msg.destination_canon].include? target
    msg.reply "There is no player #{params[0]} that can be healed."
    return
  end

  heal_player msg, target
  msg.reply "#{msg.nick} has healed \02#{params[0]}\02!", false
  
end

def on_privmsg msg
  return if msg.private? or not @active.has_key? msg.destination_canon

  if msg.text =~ /\01ACTION (atta|hit)[^ ]+ (.*?) with (.*)\01/i
    attack_player msg, $2, $3
  end

end

