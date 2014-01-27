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

require 'rubygems'
require 'nokogiri'
require 'rexml/document'
require 'yaml'
require 'prettyprint'
require 'fileutils'
require 'zlib'
require 'stringio'
require 'enhance_repo/rpm_md/update'
require 'enhance_repo/susetags/pattern_reader'
require 'enhance_repo/pattern'

module EnhanceRepo
  module RpmMd

    class Patterns < Data

      def initialize(config)
        @dir = config.dir
        @basedir = config.updatesbasedir

        # update files
        @patterns = Set.new
      end

      def empty?
        @patterns.empty?
      end

      def size
        @patterns.size
      end

      # add all patterns in a repoparts directory
      # by default look in repoparts/
      # otherwise pass the :repoparts_path option
      def read_repoparts(opts={})
        repoparts_path = opts[:repoparts_path] || File.join(@dir, 'repoparts')
        log.info "Reading patterns parts from #{repoparts_path}"
        Dir[File.join(repoparts_path, 'pattern-*.xml')].each do |patternfile|
          log.info("`-> adding pattern #{patternfile}")
          @patterns << patternfile
        end
        # end of directory iteration
      end

      # generates a patterns.xml from a list of package names
      # it compares the last version of those package names
      # with their previous ones
      #
      # outputdir is the directory where to save the patch to.
      def generate_patterns(files, outputdir)
        pats = []
        files.each do |file|
          raise "#{file} does not exist" if not File.exist?(file)
          Zlib::GzipReader.open(file) do |gz|
            pats += EnhanceRepo::Susetags::PatternReader.read_patterns_from_tags(gz)
          end
        end

        FileUtils.mkdir_p(outputdir)
        pats.each do |pat|
          pattern_filename = File.join(outputdir, "pattern-#{pat.name}_0.xml")
          File.open(pattern_filename, 'w') do |f|
            log.info "write pattern #{pattern_filename}"
            pat.write_xml(f)
          end
        end
      end

      # splits the patterns.xml file into serveral pattern files
      # it writes those files into outputdir
      # output filenames will be pattern-name_<num>.xml
      # where name is the name of the pattern
      #
      # outputdir is the directory where to save the pattern to.
      def split_patterns(outputdir)
        FileUtils.mkdir_p outputdir
        patternsfile = File.join(@dir, metadata_filename)

        # we can't split without an patterns file
        raise "#{patternsfile} does not exist" if not File.exist?(patternsfile)
        Zlib::GzipReader.open(patternsfile) do |gz|
          document = REXML::Document.new(gz)
          root = document.root
          root.each_element("pattern") do |patternElement|
            name = nil
            patternElement.each_element("name") do |elementName|
              name = elementName.text
            end
            if name == nil
              log.warning 'No name found. Setting name to NON_NAME_FOUND'
              name = 'NON_NAME_FOUND'
            end
            version = 0
            updatefilename = ""
            while ( File.exists?(patternfilename = File.join(outputdir, "pattern-#{name}_#{version.to_s}.xml") ) )
              version += 1
            end
            log.info "Saving pattern part to '#{patternfilename}'."
            File.open(patternfilename, 'w') do |patternfile|
              patternfile << patternElement
              patternfile << "\n"
            end
          end
        end
      end

      # write a update out
      def write(file)
        builder = Builder::XmlMarkup.new(:target=>file, :indent=>2)
        builder.instruct!
        xml = builder.patterns('xmlns' => "http://novell.com/package/metadata/suse/pattern",
                               'xmlns:rpm' => "http://linux.duke.edu/metadata/rpm") do |b|
          pattern_regex = Regexp.new('<pattern\s+xmlns.+>\s*$');
          @patterns.each do |pattern|
            File.open(pattern).each_line do |line|
              if ! line.start_with?("<?xml")
                if line.match(pattern_regex)
                  # all single pattern have the namespace attributes
                  # we can remove them in the combined file
                  file << "<pattern>\n"
                else
                  file << line
                end
              end
            end
          end
        end #done builder
      end
    end
  end
end
