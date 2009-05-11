
module EnhanceRepo
  module RpmMd

    # represents
    # filelist data
    #
    # See:
    # http://en.opensuse.org/Standards/Rpm_Metadata
    #
    class FileLists

      attr_reader :log
      
      def initialize(log, dir)
        @log = log
        @dir = dir
        @rpmfiles = []
      end

      def read
        Dir["#{@dir}/**/*.rpm"].each do |rpmfile|
          @rpmfiles << rpmfile
        end  
      end

      def empty?
        @rpmfiles.empty?
      end

      def write_package(file, rpmfile)
        b = Builder::XmlMarkup.new(:target=>file, :indent=>2, :initial=>2)
        pkgid = PackageId.new(rpmfile)
        b.package('pkgid'=>pkgid.checksum, 'name' => pkgid.name, 'arch'=>pkgid.arch ) do | b |
          b.version('epoch' => pkgid.version.e, 'ver' => pkgid.version.v, 'rel' => pkgid.version.r)
          pkgid.files.each do |f|
            b.file f
          end
        end
        #  done package tag
      end
      
      # write filelists.xml
      def write(file)
        builder = Builder::XmlMarkup.new(:target=>file, :indent=>2)
        builder.instruct!
        xml = builder.tag!("filelists", 'xmlns' => 'xmlns="http://linux.duke.edu/metadata/filelists"', 'packages'=> @rpmfiles.size ) do |b|
          @rpmfiles.each do |rpmfile|
            write_package(file, rpmfile)
          end
          # next package
        end
      end
      
    end

  end
end
