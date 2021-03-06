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
  register_script "Convert text to various alphabets"

  register_command "nato", :cmd_nato,  1,  0, nil, "Convert text to the NATO phonetic alphabet."
  register_command "morse", :cmd_morse, 1, 0, nil, "Convert text to Morse code."
end

def cmd_nato msg, params
  nato = ["Alpha", "Bravo", "Charlie", "Delta", "Echo", "Foxtrot", "Golf",
    "Hotel", "India", "Juliet", "Kilo", "Lima", "Mike", "November", "Oscar",
    "Papa", "Quebec", "Romeo", "Sierra", "Tango", "Uniform", "Victor",
    "Whiskey", "Xray", "Yankee", "Zulu"]
  
  msg.reply params[0].upcase.chars.map {|c| nato.select {|n| n.start_with? c }[0].to_s + " " if c =~ /[A-Z]/}.join
end

def cmd_morse msg, params
  morse = [
    "",       "",       "",       "",       "",       "",       "",       "",  
    "",       "",       "",       "",       "",       "",       "",       "",  
    "",       "",       "",       "",       "",       "",       "",       "",  
    "",       "",       "",       "",       "",       "",       "",       "",  

    "  ",     "",       "",       "",       "",       "",       "",       "",  
    "",       "",       "",       "",       "",       "",       "",       "",  
    "-----",  ".----",  "..---",  "...--",  "....-",  ".....",  "-....",  "--...",
    "---..",  "----.",  "",       "",       "",       "",       "",       "",  

    "",       ".-",     "-...",   "-.-.",   "-..",    ".",      "..-.",   "--.",  
    "....",   "..",     ".---",   "-.-",    ".-..",   "--",     "-.",     "---",  
    ".--.",   "--.-",   ".-.",    "...",    "-",      "..-",    "...-",   ".--",  
    "-..-",   "-.--",   "--..",   "",       "",       "",       "",       "",  

    "",       ".-",     "-...",   "-.-.",   "-..",    ".",      "..-.",   "--.",  
    "....",   "..",     ".---",   "-.-",    ".-..",   "--",     "-.",     "---",  
    ".--.",   "--.-",   ".-.",    "...",    "-",      "..-",    "...-",   ".--",  
    "-..-",   "-.--",   "--..",   "",       "",       "",       "",       "",  
  ]

  msg.reply params[0].chars.map { |c| morse[c.ord] if c.ord < 128 }.join(" ")
end

