
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
require 'tempdir'
require 'stringio'

class Patterns_test < Test::Unit::TestCase

  def setup
#	  $stderr << "Patterns_test"
  end

  def test_xml_output
    ARGV << "--dir" << test_data('rpms/repo-1')
    config = EnhanceRepo::ConfigOpts.new
    patterns = EnhanceRepo::RpmMd::Patterns.new(config)

    Tempdir.open do |dir|
      dir = File.join(dir, "repoparts")
      a = Array.new
      a << test_data('susetags-patterns/dvd-11.2-20.22.1.i586.pat.gz')
      a << test_data('susetags-patterns/base-11-38.5.x86_64.pat.gz')
      a << test_data('susetags-patterns/base-32bit-11-38.5.x86_64.pat.gz')
      a << test_data('susetags-patterns/32bit-11-38.5.x86_64.pat.gz')
      patterns.generate_patterns(a, dir)

      written = File.open(File.join(dir, 'pattern-multimedia_0.xml')).read
      expected = File.open(test_data('rpmmd-patterns/pattern-multimedia_0.xml')).read
      #File.rename(File.join(dir, 'pattern-multimedia_0.xml'), "/tmp/pattern-multimedia_0.xml")
      assert_xml_equal(expected, written)

      written = File.open(File.join(dir, 'pattern-base_0.xml')).read
      expected = File.open(test_data('rpmmd-patterns/pattern-base_0.xml')).read
      #File.rename(File.join(dir, 'pattern-base_0.xml'), "/tmp/pattern-base_0.xml")
      assert_xml_equal(expected, written)

      written = File.open(File.join(dir, 'pattern-base-32bit_0.xml')).read
      expected = File.open(test_data('rpmmd-patterns/pattern-base-32bit_0.xml')).read
      #File.rename(File.join(dir, 'pattern-base-32bit_0.xml'), "/tmp/pattern-base-32bit_0.xml")
      assert_xml_equal(expected, written)

      written = File.open(File.join(dir, 'pattern-32bit_0.xml')).read
      expected = File.open(test_data('rpmmd-patterns/pattern-32bit_0.xml')).read
      #File.rename(File.join(dir, 'pattern-32bit_0.xml'), "/tmp/pattern-32bit_0.xml")
      assert_xml_equal(expected, written)

      patterns.read_repoparts(:repoparts_path => dir)
      buffer = StringIO.new
      patterns.write(buffer)
      assert buffer.size > 0, "patterns file not created"

    end

  end
end
