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

module EnhanceRepo
  module RpmMd

    class Property
      attr_accessor :name
      def initialize(name)
        @name = name
      end

      def hash
        @name.hash
      end

      def eql?(other)
        @name.eql?(other.name)
      end
    end

    class ValueProperty < Property
      def initialize(name, value)
        super(name)
        @value = value
      end

      def write(builder, pkgid)
        builder.tag!(@name, @value)
      end
    end

    class DiskUsageProperty < Property

      def initialize(pkgid, rpmfile)
        super('diskusage')
        @pkgid = pkgid
        @rpmfile = rpmfile
      end
      
      def write(builder, pkgid)
        dirsizes = Hash.new
        dircount = Hash.new
        `rpm -q --queryformat \"[%{FILENAMES} %{FILESIZES}\n]\" -p #{@rpmfile}`.each_line do |line|
          file, size = line.split
          dirsizes[File.dirname(file)] = 0 if not dirsizes.has_key?(File.dirname(file))
          dircount[File.dirname(file)] = 0 if not dircount.has_key?(File.dirname(file))
          
          dirsizes[File.dirname(file)] += size.to_i
          dircount[File.dirname(file)] += 1
        end

        builder.diskusage do |b|
          b.dirs do |b|
            dirsizes.each do |k, v|
              b.dir('name' => k, 'size' => v, 'count' => dircount[k] )
            end
          end
        end      
      end
      
    end

    # represents SUSE extensions to
    # primary data
    #
    # See:
    # http://en.opensuse.org/Standards/Rpm_Metadata#SUSE_primary_data_.28susedata.xml.29
    #
    class SuseData < Data

      def initialize(dir)
        @dir = dir
        @diskusage_enabled = false

        # the following hash automatically creates a sub
        # hash for non found values
        # @properties = Hash.new { |h,v| h[v]= Hash.new }
        @properties = Hash.new

      end

      # add an attribute named name for a
      # package identified with pkgid
      def add_attribute(pkgid, prop)
        if not @properties.has_key?(pkgid)
          @properties.store(pkgid, Hash.new)
        end
        @properties[pkgid][prop.name] = prop
      end
      
      def add_eulas
        # add eulas
        Dir["#{@dir}/**/*.eula"].each do |eulafile|
          base = File.basename(eulafile, '.eula')
          # =>  look for all rpms with that name in that dir
          Dir["#{File.dirname(eulafile)}/#{base}*.rpm"].each do | rpmfile |
            pkgid = PackageId.new(rpmfile)
            if pkgid.matches(base)
              eulacontent = File.new(eulafile).read
              add_attribute(pkgid, ValueProperty.new('eula', eulacontent))
              log.info "Adding eula: #{eulafile.to_s} to #{pkgid.to_s}"
            end
          end
        end
        # end of directory iteration
      end

      def add_keywords
        # add keywords
        Dir["#{@dir}/**/*.keywords"].each do |keywordfile|
          base = File.basename(keywordfile, '.keywords')
          # =>  look for all rpms with that name in that dir
          Dir["#{File.dirname(keywordfile)}/#{base}*.rpm"].each do | rpmfile |
            pkgid = PackageId.new(rpmfile)
            if pkgid.matches(base)
              f = File.new(keywordfile)
              f.each_line do |line|
                keyword = line.chop
                add_attribute(pkgid, ValueProperty.new('keyword', keyword)) if not keyword.empty?
              end
              log.info "Adding keyword: #{keywordfile.to_s} to #{pkgid.to_s}"
            end
          end
        end
        # end of directory iteration
      end

      def empty?
        @properties.empty?
      end

      def size
        @properties.size
      end

      # write an extension file like other.xml
      def write(file)
        builder = Builder::XmlMarkup.new(:target=>file, :indent=>2)
        builder.instruct!
        xml = builder.tag!(name) do |b|
          @properties.each do |pkgid, props|
            #log.info "Dumping package #{pkgid.to_s}"
            b.package('pkgid' => pkgid.checksum, 'name' => pkgid.name) do |b|
              b.version('ver' => pkgid.version.v, 'rel' => pkgid.version.r, 'arch' => pkgid.arch, 'epoch' => 0.to_s )
              props.each do |propname, prop|
                #log.info "   -> property #{prop.name}"
                prop.write(builder, pkgid)
              end
            end # end package tag
          end # iterate over properties
        end #done builder
      end
      
      def add_disk_usage
        @diskusage_enabled = true
        log.info "Preparing disk usage..."
        # build the pkgid hash
        Dir["#{@dir}/**/*.rpm"].each do |rpmfile|
          pkgid = PackageId.new(rpmfile)
          add_attribute(pkgid, DiskUsageProperty.new(pkgid, rpmfile))
        end
      end
      
    end

  end
end
