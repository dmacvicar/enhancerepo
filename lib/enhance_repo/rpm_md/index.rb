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

require 'enhance_repo/rpm_md/resource'

module EnhanceRepo
  module RpmMd

    # represents the repomd index
    class Index < Data

      include EnhanceRepo::Logger

      attr_accessor :products, :keywords
      attr_accessor :resources

      # constructor
      # log logger object
      def initialize
        super('repomd')
        @resources = []
      end

      # Reimplemented from EnhanceRepo::RpmMd::Data
      def should_compress?
        false
      end

      # add a file resource. Takes care of setting
      # all the metadata.
      def add_file_resource(abspath, path, type=nil)
        r = Resource.new
        r.type = type
        # figure out the type of resource
        # the extname to remove is different if it is gzipped
        ext = File.extname(path)
        base = File.basename(path, ext)

        # if it was gzipped, repeat the operation
        # to get the real basename
        if ext == '.gz'
          ext = File.extname(base)
          base = File.basename(base, ext)
        end

        r.type = base if r.type.nil?
        r.location = path
        r.timestamp = File.mtime(abspath).to_i.to_s
        r.checksum = EnhanceRepo::ConfigOpts.instance.digest_class.hexdigest(File.new(abspath).read)
        r.openchecksum = r.checksum
        r.size = File.size(abspath)
        r.opensize = r.size
        if File.extname(abspath) == '.gz'
          # we have a different openchecksum
          r.openchecksum = EnhanceRepo::ConfigOpts.instance.digest_class.hexdigest(Zlib::GzipReader.new(File.new(abspath)).read)
          r.opensize = (Zlib::GzipReader.new(File.new(abspath)).read).bytesize
        end
        add_resource(r)

      end

      # add resource
      # any resource of the same location
      # is overwritten
      def add_resource(r)
        # first check if this resource is already in
        # if yes then override it
        if (index = @resources.index(r)).nil?
          # add it
          @resources << r
        else
          # replace it
          #log.warn("Resource #{r.location} already exists. Replacing.")
          @resources[index] = r
        end
      end

      # read data from a file
      def read_file(file)
        doc = REXML::Document.new(file)
        doc.elements.each('repomd/data') do |datael|
          resource = Resource.new
          resource.type = datael.attributes['type']
          datael.elements.each do |attrel|
            case attrel.name
            when 'location'
              resource.location = attrel.attributes['href']
            when 'checksum'
              resource.checksum = attrel.text
            when 'timestamp'
              resource.timestamp = attrel.text
            when 'open-checksum'
              resource.openchecksum = attrel.text
            when 'size'
              resource.size = attrel.text
            when 'open-size'
              resource.opensize = attrel.text
            when 'database_version'
              resource.database_version = attrel.text
            else
              raise "unknown tag #{attrel.name}"
            end # case
          end # iterate over data subelements
          add_resource(resource)
        end # iterate over data elements
      end

      # write the index to xml file
      def write(file)
        builder = Builder::XmlMarkup.new(:target=>file, :indent=>2)
        builder.instruct!
        xml = builder.repomd('xmlns' => "http://linux.duke.edu/metadata/repo") do
          @resources.each do |resource|
            b.data('type' => resource.type) do
              b.location('href' => resource.location)
              b.checksum(resource.checksum, 'type' => EnhanceRepo::ConfigOpts.instance.digest_name)
              b.timestamp(resource.timestamp)
              b.size(resource.size) if resource.size
              b.tag!('open-size', resource.opensize) if resource.opensize
              b.tag!('open-checksum', resource.openchecksum, 'type' => EnhanceRepo::ConfigOpts.instance.digest_name)
              b.tag!('database_version', resource.database_version) if resource.database_version
            end
          end

        end #builder

      end

    end

  end

end
