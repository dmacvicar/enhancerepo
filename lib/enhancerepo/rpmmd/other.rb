
# represents
# filelist data
#
# See:
# http://en.opensuse.org/Standards/Rpm_Metadata
#
class Other

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

  # write filelists.xml
  def write(file)
    builder = Builder::XmlMarkup.new(:target=>file, :indent=>2)
    builder.instruct!
    xml = builder.tag!("otherdata", 'xmlns' => 'xmlns="http://linux.duke.edu/metadata/other"', 'packages'=> @rpmfiles.size ) do |b|
      @rpmfiles.each do |rpmfile|
        pkgid = PackageId.new(rpmfile)
        b.package('pkgid'=>pkgid.checksum, 'name' => pkgid.name, 'arch'=>pkgid.arch ) do | b |
          b.version('epoch' => pkgid.version.e, 'ver' => pkgid.version.v, 'rel' => pkgid.version.r)
        end
        #  done package tag
      end
      # next package
    end
  end
  
end
