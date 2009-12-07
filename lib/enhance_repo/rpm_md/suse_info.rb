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
require 'builder'

module EnhanceRepo
  module RpmMd
    
    # represents SUSE extensions to repository
    # metadata (not associated with packages)
    #
    # See:
    # http://en.opensuse.org/Standards/Rpm_Metadata#SUSE_repository_info_.28suseinfo.xml.29
    #
    class SuseInfo < Data

      # expiration time
      # the generated value is
      # still calculated from repomd.xml
      # resources
      attr_accessor :expire
      attr_accessor :products
      attr_accessor :keywords

      def initialize(dir)
        @dir = dir
        @expire = nil
        @keywords = Set.new
        @products = Set.new
      end

      def empty?
        @expire.nil? and @products.empty? and @keywords.empty?
      end
      
      def write(file)
        builder = Builder::XmlMarkup.new(:target=>file, :indent=>2)
        builder.instruct!
        xml = builder.suseinfo do |b|

          # add expire tag
          b.expire(@expire.to_i.to_s) if not @expire.nil?

          if not @keywords.empty?
            b.keywords do |b|
              @keywords.each do |k|
                b.k(k)
              end
            end
          end

          if not @products.empty?
            b.products do |b|
              @products.each do |p|
                b.id(p)
              end
            end
          end

        end
      end
    end

  end
end
