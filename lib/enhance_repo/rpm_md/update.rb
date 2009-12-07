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
      attr_accessor_with_default :updateid, "unknown"
      attr_accessor_with_default :status, "stable"
      attr_accessor_with_default :from, "#{ENV['USER']}@#{ENV['HOST']}"
      attr_accessor_with_default :type, "optional"
      attr_accessor_with_default :version, 1
      attr_accessor_with_default :release, "unknown"
      attr_accessor_with_default :issued, Time.now.to_i
      attr_accessor_with_default :references, []
      attr_accessor_with_default :description, ""
      attr_accessor_with_default :title, "untitled update"
      attr_accessor_with_default :packages, []
      
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

      # detects references for the given
      # configuration
      # options:
      # :keyword => 'foo'
      #    would match foo-#123 foo#1234 FOO #1234 and other
      #    creative developer variations
      # :keywords => ['foo', 'bar']
      #    adds various keywords at once
      # :href => 'http://foo.org/?query=:id'
      #    website reference, :id is replaced with the
      #    actual detected id
      #  :title => 'SUSE bug #:id'
      #    title, :id is replaced with the detected id
      #  :type => 'bugzilla'
      #    type is just passed and set in the reference that match
      #    this options
      def each_reference_for(opts={})
        keywords = Set.new
        keywords << opts[:keyword] if opts.has_key?(:keyword)
        keywords = keywords.merge(opts[:keywords].to_set) if opts.has_key?(:keywords)

        regexps = []
        keywords.each do |keyword|
          specifier = keyword.each_char.map{|x| "#{x}\\\.?"}.join
          regexps << "#{specifier}[-|\\\s#|\\\s|#](\\\d+[-|\\\d+]*)"
        end

        regexps.each do |regexp|
          references = description.scan(/#{regexp}/i)
          references.each do |ref_id|
            ref = Reference.new
            ref.referenceid = ref_id.first
            ref.href = opts[:href].gsub(/:id/, ref_id.join) if opts.has_key?(:href)
            ref.title = opts[:title].gsub(/:id/, ref_id.join) if opts.has_key?(:title)
            ref.type = opts[:type] if opts.has_key?(:type)
            yield ref
          end
        end
      end

      # yields a reference in the passed
      # block for every detected reference from the known
      # ones
      # in the update description
      def each_detected_reference
        each_reference_for(:keyword => 'bnc', :href => 'http://bugzilla.novell.com/:id', :title => 'Novell bugzilla #:id', :type => 'bugzilla' ) {|x| yield x}
        each_reference_for(:keywords => ['rh', 'rhbz'], :href => 'http://bugzilla.redhat.com/:id', :title => 'Redhat bugzilla #:id', :type => 'bugzilla' ) {|x| yield x}
        each_reference_for(:keyword => 'bgo', :href => 'http://bugzilla.gnome.org/:id', :title => 'Gnome bug #:id', :type => 'bugzilla' ) {|x| yield x}
        each_reference_for(:keyword => 'kde', :href => 'http://bugs.kde.org/:id', :title => 'KDE bug #:id', :type => 'bugzilla' ) {|x| yield x}
        each_reference_for(:keyword => 'kde', :href => 'http://bugs.kde.org/:id', :title => 'KDE bug #:id', :type => 'bugzilla' ) {|x| yield x}
        each_reference_for(:keyword => 'cve', :href => 'http://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-:id', :title => 'CVE-:id', :type => 'cve' ) {|x| yield x}
      end
      
      # automatically set empty fields
      # needs the description to be set to
      # be somehow smart
      def smart_fill_blank_fields
        # figure out the type (optional is default)
        if description =~ /vulnerability|security|CVE|Secunia/
          @type = 'security'
        else
          @type = 'recommended' if description =~ /fix|bnc#|bug|crash/
        end

        @title = "#{type} update #{version} "
        
        # now figure out the title
        # if there is only package
        if packages.size == 1
          # then name the fix according to the package, and the type
          @title << "for #{packages.first.name}"
          @updateid = packages.first.name
        elsif packages.size < 1
          # do nothing, it is may be just a message
        else
          # figure out what the multiple packages are
          if packages.grep(/kde/).size > 1
            # assume it is a KDE update
            @title << "for KDE"
            # KDE 3 or KDE4
            @updateid = "KDE3" if packages.grep(/kde(.+)3$/).size > 1
            @updateid = "KDE4" if packages.grep(/kde(.+)4$/).size > 1
          elsif packages.grep(/kernel/).size > 1
            @title << "for the Linux kernel"
            @updateid = 'kernel'
          end
        end

        @references ||= []
        # now figure out and fill references
        each_detected_reference { |ref| @references << ref }       
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
