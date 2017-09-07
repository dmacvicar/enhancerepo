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
module EnhanceRepo
  module RpmMd
    # represents
    # primary data
    #
    # See:
    # http://en.opensuse.org/Standards/Rpm_Metadata
    #
    class Primary < Data
      attr_accessor :indent

      def initialize(dir)
        @indent = false
        @dir = dir
        @rpmfiles = []
      end

      def read_packages
        Dir["#{@dir}/**/*.rpm"].each do |rpmfile|
          @rpmfiles << rpmfile
        end
      end

      def size
        @rpmfiles.size
      end

      def empty?
        @rpmfiles.empty?
      end

      def write_package(file, rpmfile)
        b = Builder::XmlMarkup.new(:target=>file, :indent=> @indent ? 2 : 0)
        b.package('type' => 'rpm') do
          pkgid = PackageId.new(rpmfile)
          b.name pkgid.name
          b.arch pkgid.arch
          b.version('epoch' => pkgid.version.e.nil? ? "0" : pkgid.version.e.to_s, 'ver' => pkgid.version.v, 'rel' => pkgid.version.r)
          b.checksum(pkgid.checksum, 'type'=> EnhanceRepo::ConfigOpts.instance.digest_name, 'pkgid'=>'YES')
          b.summary pkgid[RPM::TAG_SUMMARY]
          b.description pkgid[RPM::TAG_DESCRIPTION]
          b.packager pkgid[RPM::TAG_PACKAGER]
          b.url pkgid[RPM::TAG_URL]
          b.time('file'=>File.mtime(rpmfile).to_i, 'build'=>pkgid[RPM::TAG_BUILDTIME])
          b.tag!('size', 'archive'=>pkgid[RPM::TAG_ARCHIVESIZE], 'installed'=>pkgid[RPM::TAG_SIZE], 'package'=>File.size(rpmfile))
          b.location('href'=>File.basename(rpmfile))
          # now the format tags
          b.format do
            b.tag!('rpm:license', pkgid[RPM::TAG_LICENSE])
            b.tag!('rpm:vendor', pkgid[RPM::TAG_VENDOR])
            b.tag!('rpm:group', pkgid[RPM::TAG_GROUP])
            b.tag!('rpm:buildhost', pkgid[RPM::TAG_BUILDHOST])
            b.tag!('rpm:sourcerpm', pkgid[RPM::TAG_SOURCERPM])
            #b.tag!('rpm:header-range', pkgid[RPM::TAG_SOURCERPM])

            # serialize dependencies
            %i[provides requires obsoletes conflicts obsoletes].each do |deptype|
              b.tag!("rpm:#{deptype}") do
                pkgid.send(deptype).reverse.each do |dep|
                  flag = nil
                  flag = 'LT' if dep.lt?
                  flag = 'GT' if dep.gt?
                  flag = 'EQ' if dep.eq?
                  flag = 'LE' if dep.le?
                  flag = 'GE' if dep.ge?
                  attrs = {'name'=>dep.name}
                  unless flag.nil?
                    attrs['pre'] = 1 if (deptype == :requires) && dep.pre?
                    attrs['flags'] = flag
                    attrs['ver'] =dep.version.v
                    attrs['epoch'] = dep.version.e.nil? ? "0" : dep.version.e.to_s
                    attrs['rel'] =dep.version.r
                  end
                  b.tag!('rpm:entry', attrs)
                end
              end
            end
          end #####
          # done with format section
        end
        #  done package tag
      end

      # write primary.xml
      def write(file)
        builder = Builder::XmlMarkup.new(:target=>file, :indent=> @indent ? 2 : 0)
        builder.instruct!
        builder.tag!("metadata", 'xmlns' => 'http://linux.duke.edu/metadata/common', 'xmlns:rpm' => 'http://linux.duke.edu/metadata/rpm', 'xmlns:suse'=>'http://novell.com/package/metadata/suse/common', 'packages'=> @rpmfiles.size ) do |_b|
          @rpmfiles.each do |rpmfile|
            write_package(file, rpmfile)
          end
        end # next package
      end
    end
  end
end
