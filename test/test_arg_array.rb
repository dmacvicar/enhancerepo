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
require_relative 'helper'
require 'stringio'

class ArrayWrapper_test < Minitest::Test
  def test_array_arg
    # write a temporary file and write
    orig_array = %w[barcelona paris newyork]
    file_array = %w[lyon zebra wolf]
    Dir.mktmpdir do |dir|
      # Create a file
      file_name = File.join(dir, 'somefile.txt')
      File.write(file_name, file_array.join('\n'))

      arg = EnhanceRepo::ArrayArg.new(orig_array + file_array)

      assert_equal(6, arg.size)
      refute_includes arg, file_name
      (orig_array + file_array).all? do |el|
        assert_includes arg, el
      end
      assert_equal(arg.to_a, orig_array + file_array)
    end
  end
end
