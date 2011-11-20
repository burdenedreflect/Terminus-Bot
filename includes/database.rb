#
# Terminus-Bot: An IRC bot to solve all of the problems with IRC bots.
# Copyright (C) 2010 Terminus-Bot Development Team
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
#


module Terminus_Bot
  class Database

    require 'psych'

    FILENAME = "data.db"

    def initialize
      @data = Hash.new

      if File.exists? FILENAME
        read_database
      else
        write_database
      end

      at_exit { write_database }
    end

    def read_database
      @data = Psych.load(IO.read(FILENAME))
    end

    def write_database
      File.open(FILENAME, "w") { |f| f.write(@data.to_yaml)}
    end

    def [](key)
      return @data[key]
    end

    def []=(key, val)
      @data[key] = val
    end

    def delete(key)
      @data.delete(key)
    end

    def to_s
      return @data.to_s
    end

    def has_key?(key)
      @data.has_key? key
    end
  end
end
