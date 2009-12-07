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
require 'enhance_repo'
require 'stringio'
require 'zlib'
require 'nokogiri'

class Index_test < Test::Unit::TestCase

  def setup
  end

  def test_reading_existing_index
    index = EnhanceRepo::RpmMd::Index.new
    repomdfile = File.join(test_data('rpms/repo-with-product'), index.metadata_filename)
    index.read_file(File.new(repomdfile))

    assert_equal 4, index.resources.size

    # now test that saving back produces the same result
    buffer = StringIO.new
    index.write(buffer)

    File.open(repomdfile) do |f|
      assert_xml_equal(f.read, buffer.string)
    end
  end
end
