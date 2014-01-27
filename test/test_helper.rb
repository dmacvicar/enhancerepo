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
require 'rubygems'
require 'test/unit'
require 'mocha'

require 'minitest/spec'
require 'minitest/autorun'

$: << File.join(File.dirname(__FILE__), "..", "lib")
require 'enhance_repo'
require 'enhance_repo/xml_comparer'
require 'active_support'
require 'diffy'
require 'equivalent-xml'


EnhanceRepo::enable_logger

def test_data(name)
  File.join(File.dirname(__FILE__), "data", name)
end

module MiniTest::Assertions

  def assert_xml_equivalent(expected, actual, message = nil)

    expected = Nokogiri::XML(expected) do |config|
      config.default_xml.noblanks
    end
    actual = Nokogiri::XML(actual) do |config|
      config.default_xml.noblanks
    end

    equal = EquivalentXml.equivalent?(expected, actual,
                                      opts = {
                                        :element_order => false,
                                        :normalize_whitespace => true })

    diff = Diffy::Diff.new(expected.to_xml(:indent => 2), actual.to_xml(:indent => 2)).to_s(:color)
    assert equal, diff
  end
end

String.infect_an_assertion :assert_xml_equivalent, :must_be_xml_equivalent_with, :only_one_argument

