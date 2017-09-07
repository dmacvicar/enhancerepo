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

describe EnhanceRepo::RpmMd::Patterns do
  before do
    @config = EnhanceRepo::ConfigOpts.instance.parse_args!(test_data('rpms/repo-1'))
    @patterns = EnhanceRepo::RpmMd::Patterns.new(@config)
  end

  describe "pattern is serialized correctly" do
    before do
      path = File.join(test_data('susetags-patterns'), 'Basis-Devel.pat.gz')
      Zlib::GzipReader.open(path) do |gz|
        patterns = EnhanceRepo::Susetags::PatternReader.read_patterns_from_tags(gz)
        @pattern = patterns.first
      end
    end

    it "should have the same xml structure as our template" do
      expected = File.read(File.join(test_data('rpmmd-patterns'), 'Basis-Devel.xml'))
      expected.must_be_xml_equivalent_with @pattern.to_xml
    end
  end

  #describe "generates yum patterns from susetags files" do

  #  Dir.mktmpdir do |dir|
  #    before do
  #      @dir = File.join(dir, "repoparts")
  #      @desc_list = []
  #      @desc_list << test_data('susetags-patterns/dvd-11.2-20.22.1.i586.pat.gz')
  #      @desc_list << test_data('susetags-patterns/base-11-38.5.x86_64.pat.gz')
  #      @desc_list << test_data('susetags-patterns/base-32bit-11-38.5.x86_64.pat.gz')
  #      @desc_list << test_data('susetags-patterns/32bit-11-38.5.x86_64.pat.gz')
  #    end

  #      it "should write the patterns correctly" do
  #        @patterns.generate_patterns(@desc_list, @dir)
  #      end

  # ['pattern-multimedia_0', 'pattern-base_0', 'pattern-base-32bit_0',
  #  'pattern-32bit_0'].each do |pat|
  #   it "should generate the xml for #{pat}" do
  #     written = File.open(File.join(@dir, "#{pat}.xml")).read
  #     expected = File.open(test_data("rpmmd-patterns/#{pat}.xml")).read
  #     expected.must_equal_xml_structure written
  #     #expected.must_be_dom_equal_with written
  #   end
  # end

  #end

  #end
end

#patterns.read_repoparts(:repoparts_path => dir)
#      buffer = StringIO.new
#      patterns.write(buffer)
#      assert buffer.size > 0, "patterns file not created"


