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
require 'enhance_repo'
require 'stringio'

class UpdateInfo_test < Test::Unit::TestCase

  def setup
#	  $stderr << "UpdateInfo_test"
  end

  def test_xml_output
    config = EnhanceRepo::ConfigOpts.instance.parse_args!(test_data('rpms/repo-1'))
    updateinfo = EnhanceRepo::RpmMd::UpdateInfo.new(config)

    Dir.mktmpdir do |dir|
      updateinfo.generate_update(['a', 'b'], File.join(dir, 'repoparts'))
      puts Dir[File.join(dir, '*')]

      updateinfo.read_repoparts(:repoparts_path => File.join(dir, 'repoparts'))

      assert ! updateinfo.empty?, "updateinfo can't be empty"
      assert_equal 1, updateinfo.size, "updateinfo contains 1 update"

      Zlib::GzipReader.open(test_data('rpms/repo-1/repodata/updateinfo.xml.gz')) do |expected_updateinfo|
        buffer = StringIO.new
        updateinfo.write(buffer)
#        assert_xml_equal(expected_updateinfo.read, buffer.string)
      end

    end

  end
end
