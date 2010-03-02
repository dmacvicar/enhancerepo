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
require 'set'
require 'trollop'
require 'enhance_repo/array_arg'

module EnhanceRepo
  
  # Configuration class to hold the options
  # passed from the command line to the
  # components doing the work
  #

  class ConfigOpts

    def read_command_line
      opts = Trollop::options do
        version "enhancerepo #{EnhanceRepo::VERSION}"
        banner <<-EOS
enhancerepo is a rpm-md metadata tool

Usage:
        enhancerepo [options]

EOS
        opt :help, 'Show help'
        opt :dir, 'The repo base directory ( where repodata/ directory is located )', :short => :r, :type => :string, :default => "./"
        opt :outputdir, 'Generate metadata to a different directory', :short => :o, :type => :string
        opt :index, "Reindex the metadata and regenerates repomd.xml, even if nothing was changed using enhancerepo. Use this if you did manual changes to the metadata", :short => :x
        opt :benchmark, 'Show benchmark statistics at the end'
  
        opt :primary, 'Add data from rpm files and generate primary.xml (EXPERIMENTAL)', :short => :p
        opt :sign, 'Generates signature for the repository using key keyid', :short => :s, :type => :string
        opt :updates, 'Add updates from *.updates files and generate updateinfo.xml', :short => :u
        opt :generate_update, 'Generates an update from the given package list comparing package\'s last version changes', :type => :strings
        opt :updates_base_dir, 'Looks for package also in <dir> Useful if you keep old packages in a different repos and updates in this one.', :type => :string
        opt :split_updates, 'Splits current updateinfo.xml into update parts files in repoparts/'
        opt :indent, 'Generate indented xml. Default: no', :short => :i
  
        opt :expire, 'Set repository expiration hint (Can be used to detect dead mirrors)', :type => :date, :short => :e
        opt :repo_product, 'Adds product compatibility information', :type => :strings
        opt :repo_keyword, 'Tags repository with keyword', :type => :strings

  # === SUSE specific package data (susedata.xml)
  
        opt :eulas, 'Reads packagename.eula files and add the information to susedata.xml', :short => :l
        opt :keywords, 'Reads packagename.keywords files and add keyword metadata to susedata.xml', :short => :k
        opt :disk_usage, 'Reads rpm packages, generates disk usage information on susedata.xml', :short => :d

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

  # === Pattern information support
  
        opt :patterns, 'Add patterns from pattern-*.xml files and generate patterns.xml', :short => :P
        opt :generate_patterns, 'Generate patterns.xml from the old style pattern given as parameter to this option', :type => :strings
        opt :split_patterns, 'Splits current patterns.xml into pattern parts files in repoparts/'
  
        # other
        opt :debug, 'Show debug information'
      end
    end
    
    
    attr_accessor :index
    attr_accessor :indent
    attr_accessor :repoproducts
    attr_accessor :repokeywords
    attr_accessor :dir
    # output dir, if specified, if not
    # we use dir
    attr_writer :outputdir
    attr_accessor :signkey
    attr_accessor :expire
    attr_accessor :primary
    attr_accessor :updates
    attr_accessor :generate_update
    attr_accessor :split_updates
    attr_accessor :updatesbasedir
    attr_accessor :eulas
    attr_accessor :keywords
    attr_accessor :diskusage
    # wether to create delta rpm files
    # and how many
    attr_accessor :create_deltas
    # whether to index delta rpms
    attr_accessor :deltas

    attr_accessor :products

    attr_accessor :benchmark

    attr_accessor :patterns
    attr_accessor :generate_patterns
    attr_accessor :split_patterns
    
    def outputdir
      return @dir if @outputdir.nil?
      return @outputdir

    end
    
    def initialize
      @repoproducts = Set.new
      @repokeywords = Set.new
      opts = read_command_line
      read_opts(opts)
      #dump(opts)
    end
    
    def read_opts(opts)
      @index = opts[:index]
      @expire = opts[:expire]
      @primary = opts[:primary]
      @repoproducts = @repoproducts.merge([*ArrayArg.new(opts[:repo_products])]) if opts[:repo_products]
      @repokeywords = @repokeywords.merge([*ArrayArg.new(opts[:repo_keywords])]) if opts[:repo_keywords]
      @signkey = opts[:sign]
      @updates = opts[:updates]
      @split_updates = opts[:split_updates]
      @generate_update = ArrayArg.new(opts[:generate_update]) if opts[:generate_update]
      @eulas = opts[:eulas]
      @keywords = opts[:keywords]
      @diskusage = opts[:disk_usage]
      @deltas = opts[:deltas]
      @create_deltas = opts[:create_deltas]
      @products = opts[:products]
      @benchmark = opts[:benchmark]
      @patterns = opts[:patterns]
      @split_patterns = opts[:split_patterns]
      @generate_patterns = Array.new(opts[:generate_patterns]) if opts[:generate_patterns]
      @updatesbasedir = Pathname.new(opts[:updates_base_dir]) if opts[:updates_base_dir]
      @outputdir = Pathname.new(opts[:outputdir]) if opts[:outputdir]
      @dir = Pathname.new(opts[:dir]) if opts[:dir]
    end
    
    def dump(opts)
      logger = EnhanceRepo.logger

      logger.info "index #{@index}"
      logger.info "expire #{@expire}"
      logger.info "primary #{@primary}"
      logger.info "repoproducts #{@repoproducts}"
      logger.info "repokeywords #{@repokeywords}"
      logger.info "signkey #{@signkey}"
      logger.info "updates #{@updates}"
      logger.info "split_updates #{@split_updates}"
      logger.info "generate_update #{@generate_update}"
      logger.info "eulas #{@eulas}"
      logger.info "keywords #{@keywords}"
      logger.info "diskusage #{@diskusage}"
      logger.info "deltas #{@deltas}"
      logger.info "create_deltas #{@create_deltas}"
      logger.info "products #{@products}"
      logger.info "benchmark #{@benchmark}"
      logger.info "patterns #{@patterns}"
      logger.info "split_patterns #{@split_patterns}"
      if not @generate_patterns.nil?
        @generate_patterns.each do |p|
          logger.info "generate_patterns #{p}"
        end
      end
      logger.info "updatesbasedir #{@updatesbasedir}"
      logger.info "outputdir #{@outputdir}"
      logger.info "dir #{@dir}"
      
    end
  end
end
