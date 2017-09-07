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

describe EnhanceRepo::RpmMd::Index do
  before do
    @index = EnhanceRepo::RpmMd::Index.new
  end

  it 'should write the same that we read' do
    repomdpath = test_data('repomd.xml')
    index_content = File.new(repomdpath).read
    @index.read_file(File.new(repomdpath))

    # now that the file is parsed, lets test wether it
    # is parsed correctly
    @index.resources.size.must_equal 3

    dump_content = ''
    @index.write(dump_content)
    index_content.must_be_xml_equivalent_with dump_content
  end
end
