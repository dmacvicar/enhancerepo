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
        pattern = self
        builder = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
          xml.pattern('xmlns' => "http://novell.com/package/metadata/suse/pattern",
                      'xmlns:rpm' => "http://linux.duke.edu/metadata/rpm") {
            xml.name pattern.name
            xml.icon pattern.icon
            xml.order pattern.order
            pattern.summary.each do |lang, text|
              if lang.empty?
                xml.summary text, 'lang' => "en"
              else
                xml.summary text, 'lang' => "#{lang}"
              end
            end
            pattern.description.each do |lang, text|
              if lang.empty?
                xml.description text, 'lang' => "en"
              else
                xml.description text, 'lang' => "#{lang}"
              end
            end
            xml.uservisible if pattern.visible
            pattern.category.each do |lang, text|
              if lang.empty?
                xml.category text, 'lang' => "en"
              else
                xml.category text, 'lang' => "#{lang}"
              end
            end
            if ! pattern.conflicts.empty?
              xml['rpm'].conflicts {
                pattern.conflicts.each do |pkg, kind|
                  xml['rpm'].entry( 'name' => pkg, 'kind' => kind)
                end
              }
            end
            if ! pattern.provides.empty?
              xml['rpm'].provides {
                pattern.provides.each do |pkg, kind|
                  xml['rpm'].entry( 'name' => pkg, 'kind' => kind)
                end
              }
            end
            if ! pattern.requires.empty?
              xml['rpm'].requires {
                pattern.requires.each do |pkg, kind|
                  xml['rpm'].entry( 'name' => pkg, 'kind' => kind)
                end
              }
            end
            if ! pattern.recommends.empty?
              xml['rpm'].recommends {
                pattern.recommends.each do |pkg, kind|
                  xml['rpm'].entry( 'name' => pkg, 'kind' => kind)
                end
              }
            end
            if ! pattern.suggests.empty?
              xml['rpm'].suggests {
                pattern.suggests.each do |pkg, kind|
                  xml['rpm'].entry( 'name' => pkg, 'kind' => kind)
                end
              }
            end
          }
        end
        io << builder.to_xml
      end
    end
    
    class Patterns < Data
      
      class PatternData

        include PatternWriter
        
        attr_accessor :name
        attr_accessor :summary
        attr_accessor :description
        attr_accessor :icon
        attr_accessor :order
        attr_accessor :visible
        attr_accessor :category
        attr_accessor :conflicts
        attr_accessor :provides
        attr_accessor :requires
        attr_accessor :recommends
        attr_accessor :suggests
        
        def initialize
          @name        = ""
          @summary     = Hash.new
          @description = Hash.new
          @icon        = ""
          @order       = 0
          @visible     = true
          @category    = Hash.new
          @conflicts   = Hash.new
          @provides    = Hash.new
          @requires    = Hash.new
          @recommends  = Hash.new
          @suggests    = Hash.new
        end
          
      end
      
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
      def generate_patterns(file, outputdir)
        raise "#{file} does not exist" if not File.exist?(file)
        patterns = []

        pattern = nil
        in_des = false
        in_req = false
        in_rec = false
        in_sug = false
        in_con = false
        in_prv = false
        kind = "package"
        cur_lang = ""
        description = ""
        requires = Array.new
        recommends = Array.new
        suggests = Array.new
        Zlib::GzipReader.open(file) do |gz|
          gz.each_line do |line|
            if line.start_with?("=Pat:")
              # save the previous one
              patterns << pattern if not pattern.nil?
              # a new patern starts here
              pattern = PatternData.new
              v = line.split(/:\s*/, 2)
              pattern.name = v[1].chomp.gsub(/\s/, '_')
            elsif line.start_with?("=Cat")
              v = line.match(/=Cat\.?(\w*):\s*(.*)$/)
              pattern.category["#{v[1]}"] = v[2].chomp
            elsif line.start_with?("=Sum")
              v = line.match(/=Sum\.?(\w*):\s*(.*)$/)
              pattern.summary["#{v[1]}"] = v[2].chomp
            elsif line.start_with?("=Ico:")
              v = line.split(/:\s*/, 2)
              pattern.icon = v[1].chomp
            elsif line.start_with?("=Ord:")
              v = line.split(/:\s*/, 2)
              pattern.order = v[1].chomp.to_i
            elsif line.start_with?("=Vis:")
              if line.include?("true")
                pattern.visible = true
              else
                pattern.visible = false
              end
            elsif line.start_with?("+Des")
              in_des = true
              cur_lang = line.match(/\+Des\.?(\w*):/)[1]
            elsif line.start_with?("-Des")
              in_des = false
              pattern.description[cur_lang] = description
              cur_lang = ""
              description = ""
            elsif line.start_with?("+Req:")
              in_req = true
              kind = "pattern"
            elsif line.start_with?("-Req:")
              in_req = false
              kind = "package"
            elsif line.start_with?("+Con:")
              in_con = true
              kind = "pattern"
            elsif line.start_with?("-Con:")
              in_con = false
              kind = "package"
            elsif line.start_with?("+Prv:")
              in_prv = true
              kind = "pattern"
            elsif line.start_with?("-Prv:")
              in_prv = false
              kind = "package"
            elsif line.start_with?("+Prc:")
              in_rec = true
              kind = "package"
            elsif line.start_with?("-Prc:")
              in_rec = false
            elsif line.start_with?("+Prq:")
              in_req = true
              kind = "package"
            elsif line.start_with?("-Prq:")
              in_req = false
            elsif line.start_with?("+Psg:")
              in_sug = true
              kind = "package"
            elsif line.start_with?("-Psg:")
              in_sug = false
            elsif in_des
              description << line
            elsif in_con
              pattern.conflicts[line.chomp] = kind
            elsif in_prv
              pattern.provides[line.chomp] = kind
            elsif in_req
              pattern.requires[line.chomp] = kind
            elsif in_rec
              pattern.recommends[line.chomp] = kind
            elsif in_sug
              pattern.suggests[line.chomp] = kind
            end
          end
        end

        patterns.each do |pat|
          pattern_dir = File.join(outputdir, 'repoparts')
          pattern_filename = File.join(pattern_dir, "pattern-#{pat.name}_0.xml")
          FileUtils.mkdir_p(pattern_dir)
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
        xml = builder.patterns do |b|
          @patterns.each do |pattern|
            File.open(pattern) do |f|
              file << f.read
            end
          end
        end #done builder
      end

    end


  end
end
