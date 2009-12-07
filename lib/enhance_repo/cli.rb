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
require 'getoptlong'
require 'rdoc/usage'
require 'enhance_repo'
require 'pathname'
require 'benchmark'
require 'fileutils'

EnhanceRepo::enable_logger

opts = GetoptLong.new(
         [ '--help', '-h',     GetoptLong::NO_ARGUMENT ],
         [ '--outputdir', '-o',     GetoptLong::REQUIRED_ARGUMENT ],
         [ '--index', '-x',  GetoptLong::NO_ARGUMENT ],
         [ '--primary', '-p',  GetoptLong::NO_ARGUMENT ],
         [ '--indent', '-i',     GetoptLong::OPTIONAL_ARGUMENT ],
         [ '--sign', '-s',     GetoptLong::REQUIRED_ARGUMENT ],
         [ '--expire', '-e',   GetoptLong::REQUIRED_ARGUMENT ],
         [ '--updates', '-u',  GetoptLong::NO_ARGUMENT ],
         [ '--generate-update', GetoptLong::REQUIRED_ARGUMENT ],
         [ '--split-updates', GetoptLong::NO_ARGUMENT ],
         [ '--updates-base-dir', GetoptLong::REQUIRED_ARGUMENT ],
         [ '--eulas', '-l',    GetoptLong::NO_ARGUMENT ],
         [ '--keywords', '-k', GetoptLong::NO_ARGUMENT ],
         [ '--disk-usage', '-d', GetoptLong::NO_ARGUMENT ],
         [ '--repo-product',   GetoptLong::REQUIRED_ARGUMENT ],
         [ '--repo-keyword',   GetoptLong::REQUIRED_ARGUMENT ],
         [ '--create-deltas',  GetoptLong::OPTIONAL_ARGUMENT ],
         [ '--deltas',  GetoptLong::NO_ARGUMENT ],
         [ '--products',  GetoptLong::NO_ARGUMENT ],
         [ '--debug',  GetoptLong::NO_ARGUMENT ],
         [ '--benchmark',  GetoptLong::NO_ARGUMENT ]
)

config = EnhanceRepo::ConfigOpts.new

dir = nil

opts.each do |opt, arg|
  case opt
  when '--help'
    RDoc::usage
  when '--outputdir'
    config.outputdir = Pathname.new(arg)
  when '--primary'
    config.primary = true
  when '--index'
    config.index = true
  when '--indent'
    config.indent = true
  when '--sign'
    config.signkey = arg
  when '--repo-product'
    config.repoproducts << arg
  when '--repo-keyword'
    config.repokeywords << arg
  when '--expire'
    config.expire = arg
  when '--updates'
    config.updates = true
  when '--generate-update'
    packages = arg.split(",")
    config.generate_update = packages
  when '--split-updates'
    config.split_updates = true
  when '--updates-base-dir'
    config.updatesbasedir = Pathname.new(arg)
  when '--eulas'
    config.eulas = true
  when '--keywords'
    config.keywords = true
  when '--disk-usage'
    config.diskusage = true
  when '--create-deltas'
    if arg == ''
      config.create_deltas = 1
    else
      config.create_deltas = arg.to_i
    end
  when '--deltas'
    config.deltas = true
  when '--products'
    config.products = true
  when '--debug'
    EnhanceRepo::enable_debug
  when '--benchmark'
    config.benchmark = true
  end
end

# Check if dir is given
if ARGV.length != 1
  EnhanceRepo.logger.fatal "Missing dir argument (try --help)"
  exit 0
end

dir = ARGV.shift

# Check if the dir is valid
#if not (File.exists?(File.join(dir + REPOMD_FILE)))
#  puts "Directory '#{dir}' is not a rpm-md repository"
#  exit 1
#end

config.dir = Pathname.new(dir)

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
    if EnhanceRepo::enable_debug
      EnhanceRepo.logger.fatal excp.class
      EnhanceRepo.logger.fatal(excp.backtrace.join("\n"))
    else
      EnhanceRepo.logger.info "Pass --debug for more information..."
    end
  end

end
EnhanceRepo.logger.info(time) if config.benchmark
