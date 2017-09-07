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
require 'zlib'

describe EnhanceRepo::RpmMd::SuseData do

  describe "a generated susedata should be what is expected" do
    before do
      @susedata = EnhanceRepo::RpmMd::SuseData.new(test_data('rpms/repo-1'))
      @susedata.add_disk_usage
      @susedata.add_keywords
      @susedata.add_eulas
    end

    it "should not be empty" do
      @susedata.wont_be_empty
    end

    it "should have 3 elements" do
      @susedata.size.must_equal 3
    end

    it "should generate the right xml" do
      Zlib::GzipReader.open(test_data('rpms/repo-1/repodata/susedata.xml.gz')) do |expected_susedata|

        buffer = StringIO.new
        @susedata.write(buffer)
        assert_xml_equivalent(expected_susedata.read, buffer.string)
      end
    end
  end
end
