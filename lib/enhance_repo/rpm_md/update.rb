#--
#
# enhancerepo is a rpm-md repository metadata tool.
# Copyright (C) 2008, 2009 Novell Inc.
# Copyright (C) 2009, Jordi Massager Pla <jordi.massagerpla@opensuse.org>
#
# Author: Duncan Mac-Vicar P. <dmacvicar@suse.de>
#         Jordi Massager Pla <jordi.massagerpla@opensuse.org>
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
require 'active_support/core_ext/module/attr_accessor_with_default'
require 'builder'
require 'rexml/document'
require 'yaml'
require 'prettyprint'
require 'set'

require 'enhance_repo/rpm_md/update_smart_fields'

module EnhanceRepo
  module RpmMd

    #
    # Represents a reference to a external bugreport
    # feature or issue for a software update
    #
    class Reference
      # uri of the reference
      attr_accessor :href
      # its type, for example, bnc (novell's bugzilla)
      attr_accessor :type
      # the id, for example 34561
      # the pair type-id should be globally unique
      attr_accessor :referenceid
      # label to display to the user
      attr_accessor :title

      def to_s
       "#{type}##{referenceid}"
      end

      # initialize a reference, per default a novell
      # bugzilla type
      def initialize
        @href = "http://bugzilla.novell.com"
        @referenceid = "none"
        @title = ""
        @type = "bugzilla"
      end
    end

    # represents one update, which can consist of various packages
    # and references
    class Update

      # methods to automatically grab data from the
      # update description
      include UpdateSmartFields

      attr_accessor :updateid
      def updateid
          @updateid ||= "unknown"
      end
      attr_accessor :status
      def status
          @status ||= "stable"
      end
      attr_accessor :from
      def from
          @from ||= "#{ENV['USER']}@#{ENV['HOST']}"
      end
      attr_accessor :type
      def type
          @type ||= "optional"
      end
      attr_accessor :version
      def version
          @version ||= 1
      end
      attr_accessor :release
      def release
          @release ||= "unknown"
      end
      attr_accessor :issued
      def issued
          @issued ||= Time.now.to_i
      end
      attr_accessor :references
      def references
          @references ||= []
      end
      attr_accessor :description
      def description
          @description ||= ""
      end
      attr_accessor :title
      def title
          @title ||= "untitled update"
      end
      attr_accessor :packages
      def packages
          @packages ||= []
      end

      def initialize
      end

      # an update is not empty if it
      # updates something
      def empty?
        packages.empty?
      end

      def suggested_filename
        "update-#{updateid}-#{version}"
      end

      # write a update out
      def write(file)
        builder = Builder::XmlMarkup.new(:target=>file, :indent=>2)
        append_to_builder(builder)
      end

      def append_to_builder(builder)
        builder.update('status' => 'stable', 'from' => from, 'version' => version, 'type' => type) do |b|
          b.title(title)
          b.id(updateid)
          b.issued(issued)
          b.release(release)
          b.description(description)
          # serialize attr_reader :eferences
          b.references do |b|
            references.each do |r|
              b.reference('href' => r.href, 'id' => r.referenceid, 'title' => r.title, 'type' => r.type )
            end
          end
          # done with references
          b.pkglist do |b|
            b.collection do |b|
              packages.each do |pkg|
                b.package('name' => pkg.name, 'arch'=> pkg.arch, 'version'=>pkg.version.v, 'release'=>pkg.version.r) do |b|
                  b.filename(File.basename(pkg.path))
                end
              end
            end # </collection>
          end #</pkglist>
          # done with the packagelist
        end
      end

    end

  end
end
