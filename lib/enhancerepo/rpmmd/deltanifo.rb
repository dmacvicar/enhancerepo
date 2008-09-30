
class DiskUsageProperty < Property

  def initialize(pkgid, rpmfile)
    super('diskusage')
    @pkgid = pkgid
    @rpmfile = rpmfile
  end
                 
  def write(builder, pkgid)
      dirsizes = Hash.new
      dircount = Hash.new
      `rpm -q --queryformat \"[%{FILENAMES} %{FILESIZES}\n]\" -p #{@rpmfile}`.each_line do |line|
        file, size = line.split
        dirsizes[File.dirname(file)] = 0 if not dirsizes.has_key?(File.dirname(file))
        dircount[File.dirname(file)] = 0 if not dircount.has_key?(File.dirname(file))
        
        dirsizes[File.dirname(file)] += size.to_i
        dircount[File.dirname(file)] += 1
      end

      builder.diskusage do |b|
        b.dirs do |b|
          dirsizes.each do |k, v|
            b.dir('name' => k, 'size' => v, 'count' => dircount[k] )
          end
        end
      end      
  end
  
end

# represents SUSE extensions to
# delta
#
# See:
# http://en.opensuse.org/Standards/Rpm_Metadata
#
class SuseData < ExtraPrimaryData

  def initialize(dir)
    super('susedata')
    @dir = dir
    @diskusage_enabled = false

    # the following hash automatically creates a sub
    # hash for non found values
    # @properties = Hash.new { |h,v| h[v]= Hash.new }
    @properties = Hash.new

  end

  # add an attribute named name for a
  # package identified with pkgid
  def add_attribute(pkgid, prop)
    if not @properties.has_key?(pkgid)
      @properties.store(pkgid, Hash.new)
    end
    @properties[pkgid][prop.name] = prop
  end
  
  def add_eulas
    # add eulas
    Dir["#{@dir}/**/*.eula"].each do |eulafile|
      base = File.basename(eulafile, '.eula')
      # =>  look for all rpms with that name in that dir
      Dir["#{File.dirname(eulafile)}/#{base}*.rpm"].each do | rpmfile |
        pkgid = PackageId.new(rpmfile)
        if pkgid.matches(base)
          eulacontent = File.new(eulafile).read
          add_attribute(pkgid, ValueProperty.new('eula', eulacontent))
          STDERR.puts "Adding eula: #{eulafile.to_s} to #{pkgid.to_s}"
        end
      end
    end
    # end of directory iteration
  end

  def add_keywords
    # add keywords
    Dir["#{@dir}/**/*.keywords"].each do |keywordfile|
      base = File.basename(keywordfile, '.keywords')
      # =>  look for all rpms with that name in that dir
      Dir["#{File.dirname(keywordfile)}/#{base}*.rpm"].each do | rpmfile |
        pkgid = PackageId.new(rpmfile)
        if pkgid.matches(base)
          f = File.new(keywordfile)
          f.each_line do |line|
            keyword = line.chop
            add_attribute(pkgid, ValueProperty.new('keyword', keyword)) if not keyword.empty?
          end
          STDERR.puts "Adding keyword: #{keywordfile.to_s} to #{pkgid.to_s}"
        end
      end
    end
    # end of directory iteration
  end

  def empty?
    @properties.empty?
  end

  # write an extension file like other.xml
  def write(file)
    builder = Builder::XmlMarkup.new(:target=>file, :indent=>2)
    builder.instruct!
    xml = builder.tag!(@name) do |b|
      @properties.each do |pkgid, props|
        #STDERR.puts "Dumping package #{pkgid.to_s}"
        b.package('pkgid' => pkgid.checksum, 'name' => pkgid.name) do |b|
          b.version('ver' => pkgid.version, 'rel' => pkgid.release, 'arch' => pkgid.arch, 'epoch' => 0.to_s )
          props.each do |propname, prop|
            #STDERR.puts "   -> property #{prop.name}"
            prop.write(builder, pkgid)
          end
        end # end package tag
      end # iterate over properties
    end #done builder
  end
  
  def add_disk_usage
    @diskusage_enabled = true
    STDERR.puts "Preparing disk usage..."
    # build the pkgid hash
    Dir["#{@dir}/**/*.rpm"].each do |rpmfile|
      pkgid = PackageId.new(rpmfile)
      add_attribute(pkgid, DiskUsageProperty.new(pkgid, rpmfile))
    end
  end
  
end
