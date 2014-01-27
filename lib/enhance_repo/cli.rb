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
require 'enhance_repo'
require 'pathname'
require 'benchmark'
require 'fileutils'

EnhanceRepo.enable_logger

dir = "."
if ! (ARGV.include?("--help") || ARGV.include?("-h") ||
      ARGV.include?("--version") || ARGV.include?("-v"))
  dir = ARGV.pop
end
config = EnhanceRepo::ConfigOpts.new(dir)

repomd = EnhanceRepo::RpmMd::Repo.new(config)

# perform the operations in a rescue block

time = Benchmark.measure do
  begin
    if config.primary
      repomd.primary.read_packages
      repomd.filelists.read
      repomd.other.read
    end

    # merge keywords and products to suseinfo
    repomd.suseinfo.products.merge(config.repoproducts)
    repomd.suseinfo.keywords.merge(config.repokeywords)

    repomd.susedata.add_eulas if config.eulas
    repomd.susedata.add_keywords if config.keywords
    repomd.susedata.add_disk_usage if config.diskusage

    if not config.generate_update.nil?
      repomd.updateinfo.generate_update(config.generate_update, File.join(config.outputdir, 'repoparts') )
    end

    repomd.updateinfo.read_repoparts if config.updates
    repomd.updateinfo.split_updates(File.join(config.outputdir, 'repoparts')) if config.split_updates

    repomd.patterns.split_patterns(File.join(config.outputdir, 'repoparts')) if config.split_patterns
    if not config.generate_patterns.nil?
      repomd.patterns.generate_patterns(config.generate_patterns, File.join(config.outputdir, 'repoparts'))
    end
    repomd.patterns.read_repoparts if config.patterns || ! config.generate_patterns.nil?

    repomd.deltainfo.create_deltas(:outputdir => config.outputdir, :n => config.create_deltas) if config.create_deltas
    repomd.deltainfo.add_deltas if config.deltas

    repomd.products.read_packages if config.products

    # add expiration date
    repomd.suseinfo.expire = config.expire if not config.expire.nil?

    # index if requested
    repomd.index if config.index

    # write the repository out
    repomd.write

    # perform signature of the repository
    repomd.sign(config.signkey) if not config.signkey.nil?
  rescue Exception => excp
    EnhanceRepo.logger.fatal excp.message
    if EnhanceRepo.enable_debug
      EnhanceRepo.logger.fatal excp.class
      EnhanceRepo.logger.fatal(excp.backtrace.join("\n"))
    else
      EnhanceRepo.logger.info "Pass --debug for more information..."
    end
  end

end
EnhanceRepo.logger.info(time) if config.benchmark
