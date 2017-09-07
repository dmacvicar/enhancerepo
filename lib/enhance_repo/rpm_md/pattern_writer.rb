# Encoding: utf-8

#--
#
# enhancerepo is a rpm-md repository metadata tool.
# Copyright (C) 2008, 2009 Novell Inc.
#
# Author: Michael Calmer <mc@suse.de>
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
require 'nokogiri'
require 'yaml'
require 'prettyprint'
require 'stringio'

module EnhanceRepo
  module RpmMd
    # helper to write out a pattern in
    # rpmmd format
    module PatternWriter
      def to_xml
        buffer = StringIO.new
        write_xml(buffer)
        buffer.string
      end

      def write_xml(io = STDOUT)
        PatternWriter.write_xml(self, io)
      end

      def self.write_xml_dependency(xml, pattern, name)
        dep = name.to_sym
        list = pattern.send(dep).keys.sort do |a, b|
          puts a
          if pattern.send(dep)[a] == 'pattern' &&
             pattern.send(dep)[b] != 'pattern'
            -1
          else
            a <=> b
          end
        end
        unless list.empty?
          xml['rpm'].send(dep) do
            list.each do |pkg|
              kind = pattern.send(dep)[pkg]
              if kind == "package"
                xml['rpm'].entry( 'name' => pkg )
              else
                xml['rpm'].entry( 'name' => "#{kind}:#{pkg}" )
              end
            end
          end
        end
      end

      def self.write_xml(pattern, io = STDOUT)
        builder = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
          xml.pattern('xmlns' => "http://novell.com/package/metadata/suse/pattern",
                      'xmlns:rpm' => "http://linux.duke.edu/metadata/rpm") do
            xml.name pattern.name
            xml.arch pattern.architecture
            xml.version 'epoch' => '0', 'ver' => pattern.version, 'rel' => pattern.release
            xml.icon pattern.icon if pattern.icon
            xml.order pattern.order
            pattern.summary.each do |lang, text|
              if lang.empty?
                xml.summary text
              else
                xml.summary text, 'lang' => lang.to_s
              end
            end
            pattern.description.each do |lang, text|
              if lang.empty?
                xml.description text
              else
                xml.description text, 'lang' => lang.to_s
              end
            end
            pattern.category.each do |lang, text|
              if lang.empty?
                xml.category text
              else
                xml.category text, 'lang' => lang.to_s
              end
            end
            xml.uservisible if pattern.visible
            write_xml_dependency(xml, pattern, :conflicts)
            write_xml_dependency(xml, pattern, :supplements)
            write_xml_dependency(xml, pattern, :provides)
            write_xml_dependency(xml, pattern, :requires)
            write_xml_dependency(xml, pattern, :recommends)
            write_xml_dependency(xml, pattern, :suggests)

            unless pattern.extends.empty?
              xml.extends do
                pattern.extends.each do |pkg, kind|
                  xml.item( 'pattern' => pkg ) if kind == "pattern"
                end
              end
            end
            unless pattern.includes.empty?
              xml.includes do
                pattern.includes.each do |pkg, kind|
                   xml.item( 'pattern' => pkg ) if kind == "pattern"
                end
              end
            end
          end
        end
        io << builder.to_xml
      end
    end
  end
end