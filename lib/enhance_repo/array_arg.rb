# Encoding: utf-8

#--
#
# enhancerepo is a rpm-md repository metadata tool.
# Copyright (C) 2008, 2009 Novell Inc.
# Author: Duncan Mac-Vicar P. <dmacvicar@suse.de>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
# MA  02110-1301, USA.  A copy of the GNU General Public License is
# also available at http://www.gnu.org/copyleft/gpl.html.
#
#++
#
module EnhanceRepo
  # Helper class to turn an array like:
  # ['a', 'b', '/foo/file.txt', 'd'] into an
  # array containing the content of file.txt
  # (each line) merged into the place of the
  # file name
  #
  class ArrayArg
    include Enumerable

    # initialize the wrapper with an array
    def initialize(array)
      @array = array
      @array ||= []
      @expanded_cache = nil
    end

    # yields one element per line in
    # the file
    def expand_file(file)
      ret = []
      File.open(file) do |f|
        f.each_line do |line|
          stripped_line = line.strip
          ret << stripped_line unless stripped_line.empty?
        end
      end
      ret
    end

    # expand the wrapped array with fles
    def expanded
      return @expanded_cache if @expanded_cache
      ret = []
      @array.each do |element|
        if File.exist?(element) && !File.directory?(element)
          EnhanceRepo.logger.info "Expanding the content of file '#{element}'..."
          ret += expand_file(element)
        else
          ret << element
        end
      end
      @expanded_cache = ret
      ret
    end

    # delegate other methods to the expanded array
    def method_missing(method, *args)
      each.to_a.send(method, *args)
    end

    # see Enumerable
    def each
      return enum_for(:each) unless block_given?
      expanded.each { |x| yield x }
      self
    end
  end
end
