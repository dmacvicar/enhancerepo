module EnhanceRepo
  module RpmMd
    # represents
    # primary data
    #
    # See:
    # http://en.opensuse.org/Standards/Rpm_Metadata
    #
    class Primary
      attr_accessor :indent
      
      attr_reader :log
      
      def initialize(log, dir)
        @indent = false
        @log = log
        @dir = dir
        @rpmfiles = []
      end

      def read
        Dir["#{@dir}/**/*.rpm"].each do |rpmfile|
          @rpmfiles << rpmfile
        end  
      end

      def size
        @rpmfiles.size
      end
      
      def empty?
        @rpmfiles.empty?
      end

      def write_package(file, rpmfile)
        b = Builder::XmlMarkup.new(:target=>file, :indent=> @indent ? 2 : 0, :indent=> @indent ? 2 : 0)
        b.package('type' => 'rpm') do | b |
          pkgid = PackageId.new(rpmfile)
          b.name pkgid.name
          b.arch pkgid.arch
          b.version('epoch' => pkgid.version.e, 'ver' => pkgid.version.v, 'rel' => pkgid.version.r)
          b.checksum(pkgid.checksum, 'type'=>'sha', 'pkgid'=>'YES')
          b.summary pkgid[RPM::TAG_SUMMARY]
          b.description pkgid[RPM::TAG_DESCRIPTION]
          b.packager pkgid[RPM::TAG_PACKAGER]
          b.url pkgid[RPM::TAG_URL]
          b.time('file'=>File.mtime(rpmfile).to_i, 'build'=>pkgid[RPM::TAG_BUILDTIME])
          b.tag!('size', 'archive'=>pkgid[RPM::TAG_ARCHIVESIZE], 'installed'=>pkgid[RPM::TAG_SIZE], 'package'=>File.size(rpmfile))
          b.location('href'=>File.basename(rpmfile))
          # now the format tags
          b.format do |b|
            b.tag!('rpm:license', pkgid[RPM::TAG_LICENSE])
            b.tag!('rpm:vendor', pkgid[RPM::TAG_VENDOR])
            b.tag!('rpm:group', pkgid[RPM::TAG_GROUP])
            b.tag!('rpm:buildhost', pkgid[RPM::TAG_BUILDHOST])
            b.tag!('rpm:sourcerpm', pkgid[RPM::TAG_SOURCERPM])
            #b.tag!('rpm:header-range', pkgid[RPM::TAG_SOURCERPM])
            
            # serialize dependencies
            [:provides, :requires, :obsoletes, :conflicts, :obsoletes].each do |deptype|
              b.tag!("rpm:#{deptype}") do |b|
                pkgid.send(deptype).each { |dep|
                  flag = nil
                  flag = 'LT' if dep.lt?
                  flag = 'GT' if dep.gt?
                  flag = 'EQ' if dep.eq?
                  flag = 'LE' if dep.le?
                  flag = 'GE' if dep.ge?
                  attrs = {'name'=>dep.name}
                  if not flag.nil?
                    attrs['pre'] = 1 if (deptype == :requires) and dep.pre?
                    attrs['flags'] = flag
                    attrs['ver'] =dep.version
                  end
                  b.tag!('rpm:entry', attrs)
                }
              end
              #####
            end
          end
          # done with format section
        end
        #  done package tag
      end
      
      # write primary.xml
      def write(file)
        builder = Builder::XmlMarkup.new(:target=>file, :indent=> @indent ? 2 : 0)
        builder.instruct!
        builder.tag!("metadata", 'xmlns' => 'http://linux.duke.edu/metadata/common', 'xmlns:rpm' => 'http://linux.duke.edu/metadata/rpm', 'xmlns:suse'=>'http://novell.com/package/metadata/suse/common', 'packages'=> @rpmfiles.size ) do |b|
          @rpmfiles.each do |rpmfile|
            write_package(file, rpmfile)
          end
        end# next package
      end
      
    end

  end
end
