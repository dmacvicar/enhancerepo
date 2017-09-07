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

class Update_test < Test::Unit::TestCase

  def setup
  end

  def test_smart_fill_blanks
    update = EnhanceRepo::RpmMd::Update.new

    update.description = "fix crash on exit"
    #assert_equal "recommended", update

    # simple test
    update.description = "bnc#1245 b.nc-4566 BNC 123 cve-3443-434 CVE-3333 bug 1234"
    refs = []
    update.each_reference_for(:keyword => 'bnc', :href => 'http://novell.com/:id', :title => 'novell bug #:id') do |r|
      refs << r
    end
    refs.each { |r| puts r.inspect }
    assert_equal 3, refs.size, "3 references should be detected"

    # test for FOO xxxx-yyyy
    refs = []
    update.each_reference_for(:keyword => 'cve', :href => 'http://cve.com/:id', :title => 'cve advisory #:id') do |r|
      refs << r
    end
    refs.each { |r| puts r.inspect }
    assert_equal 2, refs.size, "2 CVE references should be detected"

    # test for multiple keywords
    refs = []
    update.each_reference_for(:keywords => ['bug', 'bnc'], :href => 'http://novell.com/:id', :title => 'bug #:id') do |r|
      refs << r
    end
    refs.each { |r| puts r.inspect }
    assert_equal 4, refs.size, "4 bugs should be detected"

    # test the pre-configured reference detectors
    refs = []
    update.each_detected_reference do |r|
      refs << r
    end
    puts
    refs.each { |r| puts r.inspect }
    assert_equal 5, refs.size, "4 bugs should be detected"

  end

end
