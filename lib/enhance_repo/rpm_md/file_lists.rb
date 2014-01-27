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
    # filelist data
    #
    # See:
    # http://en.opensuse.org/Standards/Rpm_Metadata
    #
    class FileLists < Data

      include Logger

      def initialize(dir)
        @dir = dir
        @rpmfiles = []
      end

      def read
        Dir["#{@dir}/**/*.rpm"].each do |rpmfile|
          @rpmfiles << rpmfile
        end
      end

      def empty?
        @rpmfiles.empty?
      end

      def write_package(file, rpmfile)
        b = Builder::XmlMarkup.new(:target=>file, :indent=>2, :initial=>2)
        pkgid = PackageId.new(rpmfile)
        b.package('pkgid'=>pkgid.checksum, 'name' => pkgid.name, 'arch'=> pkgid.arch ) do | b |
          b.version('epoch' => pkgid.version.e, 'ver' => pkgid.version.v, 'rel' => pkgid.version.r)
          pkgid.files.each do |f|
            b.file f
          end
        end
        #  done package tag
      end

      # write filelists.xml
      def write(file)
        builder = Builder::XmlMarkup.new(:target=>file, :indent=>2)
        builder.instruct!
        xml = builder.filelists( 'xmlns' => "http://linux.duke.edu/metadata/filelists",
                                 'packages'=> @rpmfiles.size ) do |b|
          @rpmfiles.each do |rpmfile|
            write_package(file, rpmfile)
          end
          # next package
        end
      end

    end

  end
end
