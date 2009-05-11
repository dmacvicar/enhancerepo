require 'rubygems'
require 'builder'
require 'rexml/document'
require 'digest/sha1'
require 'enhance_repo/constants'
require 'zlib'
require 'yaml'

require 'enhance_repo/package_id'
require 'enhance_repo/rpm_md/primary'
require 'enhance_repo/rpm_md/file_lists'
require 'enhance_repo/rpm_md/other'
require 'enhance_repo/rpm_md/update_info'
require 'enhance_repo/rpm_md/suse_info'
require 'enhance_repo/rpm_md/suse_data'
require 'enhance_repo/rpm_md/delta_info'

module EnhanceRepo
  module RpmMd
    
    include REXML

    # nice hack
    class Pathname
      def extend(s)
        return Pathname.new("#{self.to_s}#{s}")
      end
    end
    
    # represents a resource in repomd.xml
    class Resource
      attr_accessor :type
      attr_accessor :location, :checksum, :timestamp, :openchecksum

      # define equality based on the location
      # as it has no sense to have two resources for the
      #same location
      def ==(other)
        return (location == other.location) if other.is_a?(Resource)
        false
      end
      
    end

    # represents the repomd index
    class Index
      attr_accessor :products, :keywords
      attr_reader :log
      
      # constructor
      # repomd - repository
      def initialize(log)
        @log = log
        @resources = []
      end

      # add a file resource. Takes care of setting
      # all the metadata.
      
      def add_file_resource(abspath, path, type=nil)
        r = Resource.new
        r.type = type
        # figure out the type of resource
        # the extname to remove is different if it is gzipped
        ext = File.extname(path)
        base = File.basename(path, ext)

        # if it was gzipped, repeat the operation
        # to get the real basename
        if ext == '.gz'
          ext = File.extname(base)
          base = File.basename(base, ext)
        end
        
        r.type = base if r.type.nil?
        r.location = abspath
        r.timestamp = File.mtime(path).to_i.to_s
        r.checksum = Digest::SHA1.hexdigest(File.new(path).read)
        r.openchecksum = r.checksum
        if File.extname(path) == '.gz'
          # we have a different openchecksum
          r.openchecksum = Digest::SHA1.hexdigest(Zlib::GzipReader.new(File.new(path)).read)
        end
        add_resource(r)
        
      end

      # add resource
      # any resource of the same location
      # is overwritten
      def add_resource(r)
        # first check if this resource is already in
        # if yes then override it
        if (index = @resources.index(r)).nil?
          # add it
          @resources << r
        else
          # replace it
          log.warn("Resource #{r.location} already exists. Replacing.")
          @resources[index] = r
        end
      end
      
      # read data from a file
      def read_file(file)
        doc = Document.new(file)
        doc.elements.each('repomd/data') do |datael|
          resource = Resource.new
          resource.type = datael.attributes['type']
          datael.elements.each do |attrel|
            case attrel.name
            when 'location'
              resource.location = attrel.attributes['href']
            when 'checksum'
              resource.checksum = attrel.text
            when 'timestamp'
              resource.timestamp = attrel.text
            when 'open-checksum'
              resource.openchecksum = attrel.text
            else
              raise "unknown tag #{attrel.name}"
            end # case
          end # iterate over data subelements
          add_resource(resource)
        end # iterate over data elements
      end
      
      # write the index to xml file
      def write(file)
        builder = Builder::XmlMarkup.new(:target=>file, :indent=>2)
        builder.instruct!
        xml = builder.repomd('xmlns' => "http://linux.duke.edu/metadata/repo") do |b|
          @resources.each do |resource|
            b.data('type' => resource.type) do |b|
              b.location('href' => resource.location)
              b.checksum(resource.checksum, 'type' => 'sha')
              b.timestamp(resource.timestamp)
              b.tag!('open-checksum', resource.openchecksum, 'type' => 'sha')
            end
          end
          
        end #builder
        
      end
      
    end

    class Repo

      attr_accessor :index

      # extensions
      attr_reader :primary, :other, :filelists, :susedata, :suseinfo, :deltainfo, :updateinfo
      attr_reader :log
      
      def initialize(log, config)
        @log = log
        @index = Index.new(log)
        # populate the index
        if (config.dir + REPOMD_FILE).exist?
          @index.read_file(File.new(config.dir + REPOMD_FILE))
        end
        @dir = config.dir
        @outputdir = config.outputdir

        @primary = Primary.new(log, config.dir)
        @primary.indent = config.indent
        
        @filelists = FileLists.new(log, config.dir)
        @other = Other.new(log, config.dir)
        @susedata = SuseData.new(log, config.dir)
        @updateinfo = UpdateInfo.new(log, config)
        @suseinfo = SuseInfo.new(log, config.dir)
        @deltainfo = DeltaInfo.new(log, config.dir)
      end

      def sign(keyid)
        # check if the index is written to disk
        repomdfile = @dir + REPOMD_FILE
        if not repomdfile.exist?
          raise "#{repomdfile} does not exist."
        end
        # call gpg to sign the repository
        `gpg -sab -u #{keyid} -o #{repomdfile}.asc #{repomdfile}`
        if not File.exists?("#{repomdfile}.asc")
          log.info "Could't not generate signature #{repomdfile}.asc"
          exit(1)
        else
          log.info "#{repomdfile}.asc signature generated"
        end

        # now export the public key
        `gpg --export -a -o #{repomdfile}.key #{keyid}`

        if not File.exists?("#{repomdfile}.key")
          log.info "Could't not generate public key #{repomdfile}.key"
          exit(1)
        else
          log.info "#{repomdfile}.key public key generated"
        end
      end

      # write back the metadata
      def write
        repomdfile = @outputdir + REPOMD_FILE
        primaryfile = (@outputdir + PRIMARY_FILE).extend('.gz')
        filelistsfile = (@outputdir + FILELISTS_FILE).extend('.gz')
        otherfile = (@outputdir + OTHER_FILE).extend('.gz')
        susedfile = (@outputdir + SUSEDATA_FILE).extend('.gz')
        updateinfofile = (@outputdir + UPDATEINFO_FILE).extend('.gz')
        suseinfofile = (@outputdir + SUSEINFO_FILE).extend('.gz')
        deltainfofile = (@outputdir + DELTAINFO_FILE).extend('.gz')

        log.info((@outputdir + OTHER_FILE))
        log.info otherfile.class
        
        write_gz_extension_file(@primary, primaryfile, PRIMARY_FILE)
        write_gz_extension_file(@filelists, filelistsfile, FILELISTS_FILE)
        write_gz_extension_file(@other, otherfile, OTHER_FILE)
        write_gz_extension_file(@updateinfo, updateinfofile, UPDATEINFO_FILE)
        write_gz_extension_file(@susedata, susedfile, SUSEDATA_FILE)
        write_gz_extension_file(@suseinfo, suseinfofile, SUSEINFO_FILE)
        write_gz_extension_file(@deltainfo, deltainfofile, DELTAINFO_FILE)
        
        # now write the index
        f = File.open((@outputdir + REPOMD_FILE), 'w')
        log.info "Saving #{repomdfile} .."
        @index.write(f)
        
      end

      # writes an extension to an xml filename if
      # the extension is not empty
      def write_gz_extension_file(extension, filename, relfilename)
        if not extension.empty?
          repomdfile = @outputdir + REPOMD_FILE
          log.info "Saving #{filename} .."
          if not filename.dirname.exist?
            log.info "Creating non existing #{filename.dirname} .."
            filename.dirname.mkpath
          end
          f = File.open(filename, 'w')
          # compress the output
          gz = Zlib::GzipWriter.new(f)
          extension.write(gz)
          gz.close
          # add it to the index
          log.info "Adding #{filename} to #{repomdfile} index"
          @index.add_file_resource("#{relfilename}.gz", filename)
        end
      end
      
    end

  end
end
