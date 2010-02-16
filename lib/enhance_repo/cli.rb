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
require 'trollop'
require 'enhance_repo'
require 'pathname'
require 'benchmark'
require 'fileutils'

EnhanceRepo::enable_logger

opts = Trollop::options do
  version "enhancerepo #{EnhanceRepo::VERSION}"
  banner <<-EOS
enhancerepo is a rpm-md metadata tool

Usage:
        enhancerepo [options] DIR

        DIR: The repo base directory ( where repodata/ directory is located )
EOS
  opt :help, 'Show help'
  opt :outputdir, 'Generate metadata to a different directory', :short => :o
  opt :index, "Reindex the metadata and regenerates repomd.xml, even if nothing was changed using enhancerepo. Use this if you did manual changes to the metadata", :short => :x
  opt :benchmark, 'Show benchmark statistics at the end'
  
  opt :primary, 'Add data from rpm files and generate primary.xml (EXPERIMENTAL)', :short => :p
  opt :sign, 'Generates signature for the repository using key keyid', :short => :s, :type => :string
  opt :updates, 'Add updates from *.updates files and generate updateinfo.xml', :short => :u
  opt :'generate-update', 'Generates an update from the given package list comparing package\'s last version changes', :type => :strings
  opt :'updates-base-dir', 'Looks for package also in <dir> Useful if you keep old packages in a different repos and updates in this one.', :type => :string
  opt :'split-updates', 'Splits current updateinfo.xml into update parts files in repoparts/'
  opt :indent, 'Generate indented xml. Default: no', :short => :i
  
  opt :expire, 'Set repository expiration hint (Can be used to detect dead mirrors)', :type => :date, :short => :e
  opt :'repo-product', 'Adds product compatibility information', :type => :strings
  opt :'repo-keyword', 'Tags repository with keyword', :type => :strings

  # === SUSE specific package data (susedata.xml)
  
  opt :eulas, 'Reads packagename.eula files and add the information to susedata.xml', :short => :l
  opt :keywords, 'Reads packagename.keywords files and add keyword metadata to susedata.xml', :short => :k
  opt :'disk-usage', 'Reads rpm packages, generates disk usage information on susedata.xml', :short => :d

  # Note: your .eula or .keywords file will be added to
  # a package if it matches its name. If you want to add
  # the attributes to a specific package, name the file
  # name-version, name-version-release or
  # name-version-release.arch

  # === Package deltas support
  opt :'create-deltas',
      'Create [num] deltas for different versions of a package. If there is foo-1.rpm, foo-2.rpm, foo-3.rpm, foo-4.rpm num=1 will create a delta to go from version 3 to 4, while num=2 will create one from 2 to 4 too. This does not index the deltas. Use --deltas for that.', :default => 1
  opt :deltas, 'Reads all *.delta.rpm files and add the information to deltainfo.xml. This indexes existing deltas, but won\'t create them. See --create-deltas for deltas creation.'

  # === Product information support

  opt :products, 'Reads release packages and generating product information in products.xml based on the information contained in the .prod files included in the packages.'

  # other
  opt :debug, 'Show debug information'
end

config = EnhanceRepo::ConfigOpts.new(opts)
dir = ARGV.shift
config.dir = Pathname.new(dir) if not dir.nil?

# Check if dir is given
if config.dir.nil?
  EnhanceRepo.logger.fatal "Missing dir argument (try --help)"
  exit 0
end

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
