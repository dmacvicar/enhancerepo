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
require 'tmpdir'
require 'log4r'
require 'enhance_repo'
require 'stringio'
require 'test/unit/xml'

include Log4r

class Primary_test < Test::Unit::TestCase

  def setup
  end

  def test_xml_output
    primary = EnhanceRepo::RpmMd::Primary.new(test_data('rpms/repo-1'))
    primary.read

    assert ! primary.empty?
    assert_equal 3, primary.size

    buffer = StringIO.new
    primary.write(buffer)
#<?xml version="1.0" encoding="UTF-8"?>
    primary_xml =<<EOF

<metadata xmlns="http://linux.duke.edu/metadata/common" xmlns:rpm="http://linux.duke.edu/metadata/rpm" xmlns:suse="http://novell.com/package/metadata/suse/common" packages="2">
<package type="rpm"><name>a</name><arch>x86_64</arch><version epoch="0" ver="1.0" rel="0"/><checksum type="sha" pkgid="YES">d153b23ee5771589ed1c488459f10602b43ebce2</checksum><summary>a package</summary><description>a simple package</description><packager/><url/><time file="1258385617" build="1258385501"/><size package="1637" installed="15" archive="264"/><location href="a-1.0-0.x86_64.rpm"/><format><rpm:license>Public Domain</rpm:license><rpm:vendor/><rpm:group>Unspecified</rpm:group><rpm:buildhost>piscola.suse.de</rpm:buildhost><rpm:sourcerpm>a-1.0-0.src.rpm</rpm:sourcerpm><rpm:header-range start="280" end="1520"/><rpm:provides><rpm:entry name="a" flags="EQ" epoch="0" ver="1.0" rel="0"/><rpm:entry name="a(x86-64)" flags="EQ" epoch="0" ver="1.0" rel="0"/></rpm:provides><rpm:requires><rpm:entry name="rpmlib(PayloadIsLzma)" flags="LE" epoch="0" ver="4.4.6" rel="1"/><rpm:entry name="rpmlib(CompressedFileNames)" flags="LE" epoch="0" ver="3.0.4" rel="1"/><rpm:entry name="rpmlib(PayloadFilesHavePrefix)" flags="LE" epoch="0" ver="4.0" rel="1"/></rpm:requires></format></package>
<package type="rpm"><name>a</name><arch>x86_64</arch><version epoch="0" ver="2.0" rel="0"/><checksum type="sha" pkgid="YES">bc6e0afe3a9529fd7cae1ff13640bd754f192960</checksum><summary>a package</summary><description>a simple package</description><packager/><url/><time file="1258385617" build="1258385553"/><size package="1642" installed="38" archive="288"/><location href="a-2.0-0.x86_64.rpm"/><format><rpm:license>Public Domain</rpm:license><rpm:vendor/><rpm:group>Unspecified</rpm:group><rpm:buildhost>piscola.suse.de</rpm:buildhost><rpm:sourcerpm>a-2.0-0.src.rpm</rpm:sourcerpm><rpm:header-range start="280" end="1520"/><rpm:provides><rpm:entry name="a(x86-64)" flags="EQ" epoch="0" ver="2.0" rel="0"/><rpm:entry name="a" flags="EQ" epoch="0" ver="2.0" rel="0"/></rpm:provides><rpm:requires><rpm:entry name="rpmlib(PayloadIsLzma)" flags="LE" epoch="0" ver="4.4.6" rel="1"/><rpm:entry name="rpmlib(CompressedFileNames)" flags="LE" epoch="0" ver="3.0.4" rel="1"/><rpm:entry name="rpmlib(PayloadFilesHavePrefix)" flags="LE" epoch="0" ver="4.0" rel="1"/></rpm:requires></format></package>

</metadata>
EOF

    assert_xml_equal primary_xml, buffer.string
    #assert_equal primary_xml, buffer.string
  end
end
