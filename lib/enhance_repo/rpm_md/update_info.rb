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
require 'builder'
require 'rexml/document'
require 'yaml'
require 'prettyprint'
require 'fileutils'
require 'zlib'
require 'enhance_repo/rpm_md/update'

module EnhanceRepo
  module RpmMd

    class UpdateInfo < Data
      
      def initialize(config)
        @dir = config.dir
        @basedir = config.updatesbasedir

        # update files
        @updates = Set.new
      end

      def empty?
        @updates.empty?
      end

      def size
        @updates.size
      end

      # add all updates in a repoparts directory
      # by default look in repoparts/
      # otherwise pass the :repoparts_path option
      def read_repoparts(opts={})
        repoparts_path = opts[:repoparts_path] || File.join(@dir, 'repoparts')
        log.info "Reading update parts from #{repoparts_path}"
        Dir[File.join(repoparts_path, 'update-*.xml')].each do |updatefile|
          log.info("`-> adding update #{updatefile}")
          @updates << updatefile
        end
        # end of directory iteration
      end

      # generates a patch from a list of package names
      # it compares the last version of those package names
      # with their previous ones
      #
      # outputdir is the directory where to save the patch to.
      def generate_update(packages, outputdir)
        
        # make a hash name -> array of packages
        log.info "Generating update part to #{outputdir} for packages #{packages.join(", ")}"
        package_index = {}

        # look all rpms in the old packages base directory plus
        # the ones in the current one
        rpmfiles = [ Dir["#{@dir}/**/*.rpm"], @basedir.nil? ? [] : Dir["#{@basedir}/**/*.rpm"]].flatten
        log.info "`-> #{rpmfiles.size} rpm packages"
        # reject unwanted files
        rpmfiles.reject! do |rpmfile|
          reject = false
          # reject all delta and src rpms
          reject = true if rpmfile =~ /\.delta\.rpm$|\.src\.rpm$/
          # now reject all the packages for which the rpm file name
          # does not match the name of the requested packages
          # so if packages is A, B and we have C-1.0.rpm it does not
          # match either /A/ nor /B/ so we reject it.
          reject = true if packages.select { |pkg| rpmfile =~ /#{pkg.gsub(/\+/, "\\\\+")}/ }.empty?
          reject
        end

        log.info "`-> #{rpmfiles.size} rpm packages were not discarded"
        log.debug "    #{rpmfiles.map { |x| File.basename(x) }.join(', ')}"
        
        # now index all rpms per package name in a hash table
        # which goes from name => list of versions
        rpmfiles.each do |rpmfile|
          rpm = PackageId.new(rpmfile)
          # now that we have the real name, reject if it is not part
          # of the requested packages to generate updates for
          next if not packages.include?(rpm.name)
          
          package_index[rpm.name] = Array.new if not package_index.has_key?(rpm.name)
          # add the rpm if there is no other rpm with the same version
          package_index[rpm.name] << rpm if not package_index[rpm.name].select { |x| x.version == rpm.version && x.name == rpm.name }.first
        end

        log.info "`-> indexed #{package_index.size} unique packages from #{rpmfiles.size} rpms"
        log.debug "    #{package_index.keys.join(', ')}"
        # do our package hash include every package?
        packages.reject! do |pkg|
          reject = false
          if not package_index.has_key?(pkg)
            log.warn "`-> the package '#{pkg}' is not available in the repository."
            reject = true
          end
          reject
        end

        update = Update.new
        
        packages.each do |pkgname|
          pkglist = package_index[pkgname]
          log.info "`-> #{pkglist.size} versions for '#{pkgname}'"
          log.debug "    #{package_index[pkgname].map {|x| x.version}.join(", ")}"
          # sort them by version
          pkglist.sort! { |a,b| a.version <=> b.version }
          pkglist.reverse!
          # now that the list is sorted, the new rpm is the first

          # if there is only one package then we don't need changelog
          if pkglist.size > 1
            # we know that there are no duplicate versions so we can
            # take the first and the second            
            first = pkglist.shift
            second = pkglist.shift
            diff = first.changelog[0, first.changelog.size - second.changelog.size] || []                        
            log.info "`-> found change #{first.ident} and #{second.ident}."
            
            log.info "`-> '#{pkgname}' has #{diff.size} change entries (#{first.changelog.size}/#{second.changelog.size})"
            update.packages << first
            diff.each do |entry|
              update.description << entry.text << "\n"          
            end
          else
            # jump to next pkgname
            next
          end
          
        end

        # do not save it if there are no packages
        if update.empty?

        end
        
        # before writing the update, figure out more
        # information
        update.smart_fill_blank_fields
        filename = ""

        FileUtils.mkdir_p outputdir
        # increase version until version is available
        while ( File.exists?(filename = File.join(outputdir, update.suggested_filename + ".xml") ))
          update.version += 1
        end
        log.info "Saving update part to '#{filename}'."
        
        File.open(filename, 'w') do |f|
          update.write(f)
        end
      end

      # splits the updateinfo file into serveral update files
      # it writes those files into outputdir
      # output filenames will be id+_splited_version.xml
      # where id is the update id
      # version is incremented when there is others update files
      # with the same id
      #
      # outputdir is the directory where to save the patch to.
      def split_updates(outputdir)
        FileUtils.mkdir_p outputdir        
        updateinfofile = File.new(File.join(@dir, metadata_filename))

        # we can't split without an updateinfo file
        raise "#{updateinfofile} does not exist" if not File.exist?(updateinfofile)
        Zlib::GzipReader.open(updateinfofile) do |gz|        
          document = REXML::Document.new(gz)
          root = document.root
          root.each_element("update") do |updateElement|
            id = nil
            updateElement.each_element("id") do |elementId|
              id = elementId.text
            end
            if id == nil
              log.warning 'No id found. Setting id to NON_ID_FOUND'
              id = 'NON_ID_FOUND'
            end
            version = 0
            updatefilename = ""
            while ( File.exists?(updatefilename = File.join(outputdir, "update-#{id}_splited_#{version.to_s}.xml") ) )
              version += 1
            end
            log.info "Saving update part to '#{updatefilename}'."
            File.open(updatefilename, 'w') do |updatefile|
              updatefile << updateElement
            end
          end
        end
      end
      
      # write a update out
      def write(file)
        builder = Builder::XmlMarkup.new(:target=>file, :indent=>2)
        builder.instruct!
        xml = builder.updates do |b|
          @updates.each do |update|
            File.open(update) do |f|
              file << f.read
            end
            #update.append_to_builder(b)
          end
        end #done builder
      end
      
    end


  end
end
