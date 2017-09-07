# Encoding: utf-8

#--
#
# enhancerepo is a rpm-md repository metadata tool.
# Copyright (C) 2008, 2009 Novell Inc.
#
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
    module UpdateSmartFields
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
        update = self
        keywords = Set.new
        keywords << opts[:keyword] if opts.key?(:keyword)
        keywords = keywords.merge(opts[:keywords].to_set) if opts.key?(:keywords)

        regexps = []
        keywords.each do |keyword|
          specifier = keyword.each_char.map { |x| "#{x}\\\.?" }.join
          regexps << "#{specifier}[-|\\\s#|\\\s|#](\\\d+[-|\\\d+]*)"
        end

        regexps.each do |regexp|
          references = update.description.scan(/#{regexp}/i)
          references.each do |ref_id|
            ref = Reference.new
            ref.referenceid = ref_id.first
            ref.href = opts[:href].gsub(/:id/, ref_id.join) if opts.key?(:href)
            ref.title = opts[:title].gsub(/:id/, ref_id.join) if opts.key?(:title)
            ref.type = opts[:type] if opts.key?(:type)
            yield ref
          end
        end
      end

      # yields a reference in the passed
      # block for every detected reference from the known
      # ones
      # in the update description
      def each_detected_reference
        each_reference_for(:keyword => 'bnc', :href => 'http://bugzilla.novell.com/:id', :title => 'Novell bugzilla #:id', :type => 'bugzilla' ) { |x| yield x }
        each_reference_for(:keywords => ['rh', 'rhbz'], :href => 'http://bugzilla.redhat.com/:id', :title => 'Redhat bugzilla #:id', :type => 'bugzilla' ) { |x| yield x }
        each_reference_for(:keyword => 'bgo', :href => 'http://bugzilla.gnome.org/:id', :title => 'Gnome bug #:id', :type => 'bugzilla' ) { |x| yield x }
        each_reference_for(:keyword => 'kde', :href => 'http://bugs.kde.org/:id', :title => 'KDE bug #:id', :type => 'bugzilla' ) { |x| yield x }
        each_reference_for(:keyword => 'kde', :href => 'http://bugs.kde.org/:id', :title => 'KDE bug #:id', :type => 'bugzilla' ) { |x| yield x }
        each_reference_for(:keyword => 'cve', :href => 'http://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-:id', :title => 'CVE-:id', :type => 'cve' ) { |x| yield x }
      end

      # automatically set empty fields
      # needs the description to be set to
      # be somehow smart
      def smart_fill_blank_fields
        update = self
        # figure out the type (optional is default)
        if update.description =~ /vulnerability|security|CVE|Secunia/
          update.type = 'security'
        else
          update.type = 'recommended' if update.description =~ /fix|bnc#|bug|crash/
        end

        update.title = "#{update.type} update #{update.version} "

        # now figure out the title
        # if there is only package
        if update.packages.size == 1
          # then name the fix according to the package, and the type
          update.title << "for #{update.packages.first.name}"
          update.updateid = update.packages.first.name
        elsif update.packages.empty?
          # do nothing, it is may be just a message
        else
          # figure out what the multiple packages are
          if update.packages.grep(/kde/).size > 1
            # assume it is a KDE update
            update.title << "for KDE"
            # KDE 3 or KDE4
            update.updateid = "KDE3" if update.packages.grep(/kde(.+)3$/).size > 1
            update.updateid = "KDE4" if update.packages.grep(/kde(.+)4$/).size > 1
          elsif update.packages.grep(/kernel/).size > 1
            update.title << "for the Linux kernel"
            update.updateid = 'kernel'
          end
        end

        # now figure out and fill references
        each_detected_reference { |ref| update.references << ref }
      end
    end
  end
end
