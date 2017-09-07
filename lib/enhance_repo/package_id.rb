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

require 'rpm'

module EnhanceRepo
  # thin wrapper over rpm package
  class PackageId
    attr_accessor :checksum
    attr_accessor :path
    attr_accessor :rpm

    include Logger

    def initialize(rpmfile)
      @path = rpmfile
      @rpm = RPM::Package.open(rpmfile)
      @checksum = EnhanceRepo::ConfigOpts.instance.digest_class.hexdigest(File.new(rpmfile).read)
    end

    # Forward other methods
    def method_missing(sym, *args)
      @rpm.send(sym, *args)
    end

    def hash
      @checksum.hash
    end

    def eql?(other)
      @checksum == other.checksum
    end

    def arch
      s = self[RPM::TAG_SOURCERPM]
      if s.nil?
        return "src"
      else
        return @rpm.arch
      end
    end

    # match function at name and nvr level
    def matches(ident)
      # if the name matches, then it is sufficient
      return true if ident == @rpm.name
      # if not, compare the edition without release
      return true if ident == "#{@rpm.name}-#{@rpm.version.v}"
      # if not, compare the edition with release
      return true if ident == "#{@rpm.name}-#{@rpm.version.v}-#{@rpm.version.r}"
      # if not, also the architecture
      return true if ident == "#{@rpm.name}-#{@rpm.version.v}-#{@rpm.version.r}"
      # and finally arch
      return true if ident == "#{@rpm.name}-#{@rpm.version.v}-#{@rpm.version.r}.#{@rpm.arch}"
      return false
    end

    def to_s
      @rpm.to_s
    end

    def ident
      "#{@rpm}.#{@rpm.arch}"
    end
  end
end
