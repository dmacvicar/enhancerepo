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
require 'enhance_repo/rpm_md/index'

module EnhanceRepo
  module RpmMd
    
    include REXML

    # nice hack
    class Pathname
      def extend(s)
        return Pathname.new("#{self.to_s}#{s}")
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
        primaryfile = @outputdir + "#{PRIMARY_FILE}.gz"
        filelistsfile = @outputdir + "#{FILELISTS_FILE}.gz"
        otherfile = @outputdir + "#{OTHER_FILE}.gz"
        susedfile = @outputdir + "#{SUSEDATA_FILE}.gz"
        updateinfofile = @outputdir + "#{UPDATEINFO_FILE}.gz"
        suseinfofile = @outputdir + "#{SUSEINFO_FILE}.gz"
        deltainfofile = @outputdir + "#{DELTAINFO_FILE}.gz"

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
