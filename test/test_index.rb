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
require File.join(File.dirname(__FILE__), 'test_helper')
require 'enhance_repo'
require 'stringio'
require 'zlib'
require 'nokogiri'

describe EnhanceRepo::RpmMd::Index do

  before do
    @index = EnhanceRepo::RpmMd::Index.new
    @repomdfile = File.join(test_data('rpms/repo-with-product'), @index.metadata_filename)
    @index.read_file(File.new(@repomdfile))
  end

  it "should have four resources" do
    @index.resources.size.must_equal 4
  end

  it "saving it back should produce the same initial xml" do
    buffer = StringIO.new
    @index.write(buffer)

    original = File.read(@repomdfile)
    buffer.string.must_be_xml_equivalent_with original
  end
end
