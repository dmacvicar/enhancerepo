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
require File.join(File.dirname(__FILE__), 'test_helper')
require 'enhance_repo/array_arg'
require 'tempdir'
require 'stringio'

class ArrayWrapper_test < Test::Unit::TestCase
  
  def test_array_arg
    # write a temporary file and write
    orig_array = ['barcelona', 'paris', 'newyork' ]
    Tempdir.open do |dir|     
      # Create a file
      file_name = File.join(dir, 'somefile.txt')
      file_array = ['lyon', 'zebra', 'wolf']
      File.open(file_name, 'w+') do |f|
        file_array.each do |element|
          f.puts element
        end        
      end

      # add the file name
      array = orig_array
      array.insert(1, file_name)
      
      arg = EnhanceRepo::ArrayArg.new(array)

      assert_equal(6, arg.size)
      assert(!arg.include?(file_name), "orginal file should not be included")
      (orig_array + file_array).all? do |x|
        assert arg.include?(x), "element '#{x}' should be included"
      end
      assert_equal("barcelona,lyon,zebra,wolf,paris,newyork", arg.join(','))
    end
  
  end
end
