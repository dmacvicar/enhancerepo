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
require 'rpm'
require 'tmpdir'
require 'pathname'
require 'nokogiri'
require 'ftools'

module EnhanceRepo
  module RpmMd

    # products.xml metadata generator
    # reads the release files from a repository
    class Products
      
      include Logger

      class ProductData
        attr_accessor :name
        attr_accessor :vendor
        attr_accessor :version
        attr_accessor :release
        attr_accessor :arch
        attr_accessor :productline
        attr_accessor :summary
        attr_accessor :description
      end
      
      def initialize(dir)
        @dir = dir
        @products = []
      end

      def rpm_extract_file(rpmpath, path)
        tmppath = File.join(Dir.tmpdir, 'enhancerepo')
        File.makedirs(tmppath)
        Dir.chdir(tmppath) do
          `rpm2cpio #{rpmpath} | cpio -iv --make-directories #{File.join(".", path)} 2>/dev/null`
        end
        File.open(File.join(tmppath, path)) do |f|
          yield f if block_given?
          return f.read
        end
      end

      def products_in_file_in_rpm(rpmpath, path)
        products = []
        rpm_extract_file(rpmpath, path) do |f|
          doc = Nokogiri::XML(f)
          product = ProductData.new
          products << product
          yield product if block_given?
        end
        products
      end

      # scan the products from the rpm files in the repository
      def read_packages
        log.info "Looking for product release packages"
        Dir["#{@dir}/**/*-release-*.rpm"].each do |rpmfile|
          log.info rpmfile
          pkg = RPM::Package.new(rpmfile)
          # we dont care for packages not providing a product
          next if pkg.provides.select{|x| x.name == "product()"}.empty?
          log.info "Found product release package #{rpmfile}"
          # this package contains a product
          # go over each product file
          pkg.files.map {|x| x.to_s }.each do |path|
            next if not ( File.extname(path) == ".prod" && File.dirname(path) == "/etc/products.d" )
            # we have a product file. Extract it
            log.info "`-> product file : #{path}"
            products_in_file_in_rpm(File.expand_path(rpmfile), File.expand_path(path)) do |product|
              log.info "`-> found product : #{product.name}"
              @products << product
            end
          end
        end
      end

      def empty?
        @products.empty?
      end

      def write(io)
      end

      
    end
    
  end
end
