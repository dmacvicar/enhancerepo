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
require 'tmpdir'
require 'pathname'
require 'rubygems'
require 'enhance_repo'
require 'stringio'

class RpmMd_test < Test::Unit::TestCase

  def setup
#    $stderr << "RpmMd_test"
    rpms = Pathname.new(File.join(File.dirname(__FILE__), 'data', 'rpms'))
    @rpms1 = rpms + 'update-test-11.1'
    @rpms3 = rpms + 'update-test-factory'
  end

  # def teardown
  # end

  def test_disk_info
    ARGV << "--outputdir" << File.join(Dir.tmpdir, 'enhancerepo#{Time.now.to_i}') << "--primary"
    config = EnhanceRepo::ConfigOpts.instance.parse_args!(@rpms1)
    #config.outputdir = Pathname.new(File.join(Dir.tmpdir, 'enhancerepo#{Time.now.to_i}'))
    #config.dir = @rpms1
    @repo = EnhanceRepo::RpmMd::Repo.new(config)
    @repo.primary.read_packages
    out = StringIO.new
    @repo.primary.write(out)
    #puts out.string
  end

  def test_update_info
    #config.generate_update = packages
  end
end
