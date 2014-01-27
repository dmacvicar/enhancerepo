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

require 'rubygems'
require 'nokogiri'
require 'yaml'
require 'rpm'
require 'pp'
require 'pathname'

module EnhanceRepo
  module RpmMd

    include REXML

    class DeltaRpm < PackageId
      attr_accessor :sequence, :sourcerpm

      def initialize(filename)
        super(filename)
        `applydeltarpm -i '#{filename}'`.each_line do |line|
          key, value = line.chop.split(':')
          value.gsub!(/ /, '')
          @sequence = value if key == "sequence"
          @sourcerpm = value if key == "source rpm"
        end
      end

      def hash
        ident.hash
      end

      def eql?(other)
        ident == other.ident
      end

    end

    class DeltaInfo < Data

      def initialize(dir)
        @dir = dir
        # here we store known deltas
        # we index by new package
        # and in every slot we store an
        # array with such deltas
        @deltas = Hash.new
      end

      def delta_count
        @deltas.size
      end

      def empty?
        return @deltas.empty?
      end

      # Create delta rpms for the last
      # n versions of some rpm.
      #
      # So if you have
      # foo-4.rpm
      # foo-3.rpm
      # foo-2.rpm
      # foo-1.rpm
      #
      # Creating deltas with n = 1 will
      # create a delta for going to
      # version 3 to 4. While n = 2 would
      # create a delta to go from 2 to 4 too.
      #
      # options are :n => number of deltas (default 1)
      # and :outputdir => defaulting to the same
      # input directory
      def create_deltas(opts={})
        outputdir = opts[:outputdir] || @dir
        n = opts[:n] || 1

        log.info "Scanning rpms for delta generation (#{n} levels)"
        #log.info "Creating deltarpms : level #{n}"
        # make a hash name -> array of packages
        pkgs = Hash.new

        Dir["#{@dir}/**/*.rpm"].each do |rpmfile|
          #puts "Delta: #{rpmfile}"
          rpm = PackageId.new(rpmfile)

          pkgs[rpm.name] = Array.new if not pkgs.has_key?(rpm.name)
          pkgs[rpm.name] << rpm
        end

        # now that we have al packages, sort them by version
        pkgs.each do |pkgname, pkglist|

          pkglist.sort! { |a,b| a.version <=> b.version }
          pkglist.reverse!
          # now that the list is sorted, the new rpm is the first
          newpkg = pkglist.shift
          c = 0
          if not pkglist.empty?
            for pkg in pkglist
              break if c == n
              # do not create a delta for the same package
              next if newpkg.version == pkg.version
              # do not create a delta for different archs
              next if newpkg.arch != pkg.arch
              oldpkg = pkg
              # use the same dir as the new rpm
              log.info "`-> creating delta - #{oldpkg.to_s} -> #{newpkg.to_s} (#{c+1}/#{n})"
              # calculate directory where to save the delta. Use the newpkg
              # relative to the origin directory,
              # this only works because we know the rpm is inside @dir
              subdir = Pathname.new(newpkg.path).relative_path_from(Pathname.new(@dir)).dirname
              # calculate the deltarpm name
              deltafile = File.join(outputdir, subdir, delta_package_name(oldpkg,newpkg))
              FileUtils.mkdir_p File.dirname(deltafile)
              #puts "makedeltarpm #{oldpkg.path} #{newpkg.path} #{deltafile}"
              `makedeltarpm '#{oldpkg.path}' '#{newpkg.path}' '#{deltafile}'`
              c += 1
            end
          end

        end

      end

      # figure out the name of a delta rpm
      def delta_package_name(oldpkg, newpkg)
        deltarpm = ""
        if ( oldpkg.version.v == newpkg.version.v )
          # if the version is the same, then it is specified only once, and the range
          # is used for the releases
          deltarpm = "#{oldpkg.name}-#{oldpkg.version.v}-#{oldpkg.version.r}_#{newpkg.version.r}.#{oldpkg.arch}.delta.rpm"
        else
          deltarpm = "#{oldpkg.name}-#{oldpkg.version.v}_#{newpkg.version.v}-#{oldpkg.version.r}_#{newpkg.version.r}.#{oldpkg.arch}.delta.rpm"
        end
      end

      def add_deltas
        Dir["#{@dir}/**/*.delta.rpm"].each do |deltafile|
          delta = DeltaRpm.new(deltafile)
          #puts "Delta: #{deltafile} for '#{delta.ident}'"      
          @deltas[delta] = Array.new if @deltas[delta].nil?
          @deltas[delta] << delta
        end

      end

      # write a update out
      def write(file)
        builder = Nokogiri::XML::Builder.new do |b|
          b.deltainfo do
            @deltas.each do |ident, deltas|
              b.newpackage( 'name' => ident.name, 'arch' => ident.arch,
                            'version' => ident.version.v,
                            'release' => ident.version.r ) do |b|
                deltas.each do |delta|
                  # get the edition by getting the name out
                  version = RPM::Version.new(delta.sourcerpm.gsub(/#{Regexp.escape(delta.name)}-/, ''))
                  b.delta('oldepoch'=>0, 'oldversion'=>version.v, 'oldrelease'=>version.r) do |b|
                    # remove the base dir, make it relative
                    delta_abs_path = Pathname.new(delta.path).realpath
                    base_dir_abs_path = Pathname.new(@dir).realpath
                    relative_path = delta_abs_path.relative_path_from(base_dir_abs_path)
                    b.filename relative_path
                    b.sequence(delta.sequence)
                    b.size(File.size(delta.path))
                    b.checksum(delta.checksum, 'type'=>'sha')
                  end # </delta>
                end
              end # </newpackage>
            end # each delta
          end #</deltainfo>
        end
        # ready builder
        file.write(builder.doc.to_xml(:save_with => Nokogiri::XML::Node::SaveOptions::AS_XML))
      end

    end


  end
end
