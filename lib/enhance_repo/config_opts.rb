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

module EnhanceRepo
  
  # Configuration class to hold the options
  # passed from the command line to the
  # components doing the work
  #

  class ConfigOpts
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
    
    def outputdir
      return @dir if @outputdir.nil?
      return @outputdir
    end
    
    def initialize
      @indent = false
      @primary = false
      @repoproducts = Set.new
      @repokeywords = Set.new
      @signkey = nil
      @updates = false
      @split_updates = false
      @eulas = false
      @keywords = false
      @diskusage = false
      @deltas = false
      @create_deltas = false
      @products = false
      @benchmark = false
    end
  end
end
