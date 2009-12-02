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
require 'rexml/document'
require 'digest/sha1'
require 'zlib'
require 'yaml'

require 'enhance_repo/package_id'
require 'enhance_repo/rpm_md/primary'
require 'enhance_repo/rpm_md/file_lists'
require 'enhance_repo/rpm_md/other'
require 'enhance_repo/rpm_md/update_info'
require 'enhance_repo/rpm_md/suse_info'
require 'enhance_repo/rpm_md/suse_data'
require 'enhance_repo/rpm_md/delta_info'
require 'enhance_repo/rpm_md/products'
require 'enhance_repo/rpm_md/index'

module EnhanceRepo
  module RpmMd
    
    include REXML
    
    class Repo

      include Logger
      
      attr_accessor :index

      # extensions
      attr_reader :primary, :other, :filelists, :susedata, :suseinfo, :deltainfo, :updateinfo, :products
      def initialize(config)
        @index = Index.new
        # populate the index
        if (config.dir + REPOMD_FILE).exist?
          @index.read_file(File.new(config.dir + REPOMD_FILE))
        end
        @dir = config.dir
        @outputdir = config.outputdir

        @primary = Primary.new(config.dir)
        @primary.indent = config.indent
        
        @filelists = FileLists.new(config.dir)
        @other = Other.new(config.dir)
        @susedata = SuseData.new(config.dir)
        @updateinfo = UpdateInfo.new(config)
        @suseinfo = SuseInfo.new(config.dir)
        @deltainfo = DeltaInfo.new(config.dir)
        @products = Products.new(config.dir)
      end

      def sign(keyid)
        # check if the index is written to disk
        repomdfile = @dir + REPOMD_FILE
        if not repomdfile.exist?
          raise "#{repomdfile} does not exist."
        end
        # call gpg to sign the repository
        `gpg -sab -u #{keyid} -o #{repomdfile}.asc #{repomdfile}`
        if not File.exists?("#{repomdfile}.asc")
          log.info "Could't not generate signature #{repomdfile}.asc"
          exit(1)
        else
          log.info "#{repomdfile}.asc signature generated"
        end

        # now export the public key
        `gpg --export -a -o #{repomdfile}.key #{keyid}`

        if not File.exists?("#{repomdfile}.key")
          log.info "Could't not generate public key #{repomdfile}.key"
          exit(1)
        else
          log.info "#{repomdfile}.key public key generated"
        end
      end

      # write back the metadata
      def write
        repomdfile = @outputdir + REPOMD_FILE
        primaryfile = @outputdir + "#{PRIMARY_FILE}.gz"
        filelistsfile = @outputdir + "#{FILELISTS_FILE}.gz"
        otherfile = @outputdir + "#{OTHER_FILE}.gz"
        susedfile = @outputdir + "#{SUSEDATA_FILE}.gz"
        updateinfofile = @outputdir + "#{UPDATEINFO_FILE}.gz"
        suseinfofile = @outputdir + "#{SUSEINFO_FILE}.gz"
        deltainfofile = @outputdir + "#{DELTAINFO_FILE}.gz"
        productsfile = @outputdir + "#{PRODUCTS_FILE}.gz"

        write_gz_extension_file(@primary, primaryfile, PRIMARY_FILE)
        write_gz_extension_file(@filelists, filelistsfile, FILELISTS_FILE)
        write_gz_extension_file(@other, otherfile, OTHER_FILE)
        write_gz_extension_file(@updateinfo, updateinfofile, UPDATEINFO_FILE)
        write_gz_extension_file(@susedata, susedfile, SUSEDATA_FILE)
        write_gz_extension_file(@suseinfo, suseinfofile, SUSEINFO_FILE)
        write_gz_extension_file(@deltainfo, deltainfofile, DELTAINFO_FILE)
        write_gz_extension_file(@products, productsfile, PRODUCTS_FILE)
        
        # now write the index
        f = File.open((@outputdir + REPOMD_FILE), 'w')
        log.info "Saving #{repomdfile} .."
        @index.write(f)
        
      end

      # writes an extension to an xml filename if
      # the extension is not empty
      def write_gz_extension_file(extension, filename, relfilename)
        if not extension.empty?
          repomdfile = @outputdir + REPOMD_FILE
          log.info "Saving #{filename} .."
          if not filename.dirname.exist?
            log.info "Creating non existing #{filename.dirname} .."
            filename.dirname.mkpath
          end
          f = File.open(filename, 'w')
          # compress the output
          gz = Zlib::GzipWriter.new(f)
          extension.write(gz)
          gz.close
          # add it to the index
          log.info "Adding #{filename} to #{repomdfile} index"
          @index.add_file_resource("#{relfilename}.gz", filename)
        end
      end
      
    end

  end
end
