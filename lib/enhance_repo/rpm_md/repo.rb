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
require 'builder'
require 'rexml/document'
require 'zlib'
require 'yaml'

require 'enhance_repo/package_id'
require 'enhance_repo/rpm_md/data'
require 'enhance_repo/rpm_md/primary'
require 'enhance_repo/rpm_md/file_lists'
require 'enhance_repo/rpm_md/other'
require 'enhance_repo/rpm_md/update_info'
require 'enhance_repo/rpm_md/patterns'
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
      attr_reader :primary, :other, :filelists, :susedata, :suseinfo, :deltainfo, :updateinfo, :products, :patterns
      def initialize(config)
        @dir = config.dir
        @outputdir = config.outputdir

        @index = Index.new
        repomdfile = File.join(@dir, @index.metadata_filename)
        # populate the index
        if File.exist?(repomdfile)
          @index.read_file(File.new(repomdfile))
        end

        @primary = Primary.new(config.dir)
        @primary.indent = config.indent

        @filelists = FileLists.new(config.dir)
        @other = Other.new(config.dir)
        @susedata = SuseData.new(config.dir)
        @updateinfo = UpdateInfo.new(config)
        @suseinfo = SuseInfo.new(config.dir)
        @deltainfo = DeltaInfo.new(config.dir)
        @products = Products.new(config.dir)
        @patterns = Patterns.new(config)
      end

      def sign(keyid)
        # check if the index is written to disk
        repomdfile = File.join(@dir, @index.metadata_filename)
        if not File.exist?(repomdfile)
          raise "#{repomdfile} does not exist."
        end
        # call gpg to sign the repository
        `gpg -sab -u #{keyid} -o '#{repomdfile}.asc' '#{repomdfile}'`
        if not File.exists?("#{repomdfile}.asc")
          log.info "Could't not generate signature #{repomdfile}.asc"
          exit(1)
        else
          log.info "#{repomdfile}.asc signature generated"
        end

        # now export the public key
        `gpg --export -a -o '#{repomdfile}.key' #{keyid}`

        if not File.exists?("#{repomdfile}.key")
          log.info "Could't not generate public key #{repomdfile}.key"
          exit(1)
        else
          log.info "#{repomdfile}.key public key generated"
        end
      end

      def write

        datas = [@primary, @filelists, @other, @updateinfo,
                 @susedata, @suseinfo, @deltainfo, @products, @patterns ]

        # select the datas that are not empty
        # those need to be saved
        non_empty_data = datas.reject { |x| x.empty? }
        # files present in the index, which were changed
        changed_files = []
        # files present on disk, but not in the index
        missing_files = []
        # files present in the index, but not on disk
        superflous_files = []

        # now look for files that changed or dissapeared
        Dir.chdir(@dir) do
          # look all files except the index itself
          metadata_files = Dir["repodata/*.xml*"].reject do |x|
            x  =~ /#{@index.metadata_filename}/ ||
            x =~ /\.key$/ ||
            x =~ /\.asc$/
          end
          # remove datas in the index not present in the disk
          @index.resources.reject! do |resource|
            reject = ! metadata_files.include?(resource.location)
            log.info "Removing not existing #{resource.location} from index" if reject
            reject
          end

          non_empty_files = non_empty_data.map { |x| x.metadata_filename }
          # ignore it if it is already in the non_empty_list
          # as it will be added to the index anyway
          metadata_files.reject!{ |x| non_empty_files.include?(x) }
          metadata_files.each do |metadata_file|
            # find the indexed resource for this file
            indexed_resource = @index.resources.select { |x| x.location == metadata_file }.first
            # add it to the list of changed resources if the timestamp
            # are differents
            if indexed_resource.nil?
              missing_files << metadata_file
              next
            elsif File.mtime(File.join(@dir, metadata_file)).to_i != indexed_resource.timestamp.to_i
              changed_files << metadata_file
              next
            end
          end
        end

        # write down changed datas
        non_empty_data.each do |data|
          write_gz_extension_file(data)
        end

        # update the index
        non_empty_data.each do |d|
          log.info "Adding #{d.metadata_filename} to #{@index.metadata_filename} index"
          @index.add_file_resource(File.join(@outputdir, d.metadata_filename), d.metadata_filename)
        end

        missing_files.each do |f|
          log.info "Adding missing #{f} to #{@index.metadata_filename} index"
          @index.add_file_resource(File.join(@outputdir, f), f)
        end

        changed_files.each do |f|
          log.info "Replacing changed #{f} on #{@index.metadata_filename} index"
          @index.add_file_resource(File.join(@outputdir, f), f)
        end

        # now write the index
        if !File.exist?(File.dirname(File.join(@outputdir, @index.metadata_filename)))
          FileUtils.mkdir_p(File.dirname(File.join(@outputdir, @index.metadata_filename)))
        end
        File.open(File.join(@outputdir, @index.metadata_filename), 'w') do |f|
          log.info "Saving #{@index.metadata_filename} .."
          @index.write(f)
        end
      end

      # writes an extension to an xml filename if
      # the extension is not empty
      def write_gz_extension_file(data)
        filename = Pathname.new(File.join(@outputdir, data.metadata_filename))
        FileUtils.mkdir_p filename.dirname
        log.info "Saving #{filename} .."
        if not filename.dirname.exist?
          log.info "Creating non existing #{filename.dirname} .."
          filename.dirname.mkpath
        end
        # compress the output
        Zlib::GzipWriter.open(filename) do |gz|
          data.write(gz)
        end
      end

    end

  end
end
