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
require 'tempdir'
require 'fileutils'

class Repo_test < Test::Unit::TestCase

  def setup
  end

  def test_reading_existing_repo
    Tempdir.open do |dir|
      # copy the repodata of a repository to a temp directory
      FileUtils.cp_r File.join(test_data('rpms/repo-with-product/repodata')), dir

      config = EnhanceRepo::ConfigOpts.new(dir)
      config.outputdir = dir

      repo = EnhanceRepo::RpmMd::Repo.new(config)
      assert_equal 4, repo.index.resources.size, "repository index has 4 resources"
      FileUtils.rm File.join(dir, 'repodata/filelists.xml.gz')
      repo.write

      # start again
      repo = EnhanceRepo::RpmMd::Repo.new(config)
      assert_equal 3, repo.index.resources.size, "repository index has 3 resources, after deleting one"

      ['newdata1.xml', 'newdata2.xml'].each do |newdata|
        Zlib::GzipWriter.open(File.join(dir, "repodata/#{newdata}.xml.gz")) do |f|
          f.write('<xml></xml>')
        end
      end

      File.open(File.join(dir, "repodata/newdata3.xml"), 'w') do |f|
        f.write('<xml></xml>')
      end

      repo.write

      repo = EnhanceRepo::RpmMd::Repo.new(config)
      assert_equal 6, repo.index.resources.size, "repository index has 6 resources, after adding three"
    end
  end
end
