
require 'digest/sha1'
require 'rpm'

# thin wrapper over rpm package
class PackageId
  attr_accessor :checksum
  attr_accessor :path
  attr_accessor :rpm
  
  def initialize(rpmfile)
    @path = rpmfile
    @rpm = RPM::Package.open(rpmfile)    
    @checksum = Digest::SHA1.hexdigest(File.new(rpmfile).read)
  end

  # Forward other methods
  def method_missing(sym, *args)
    @rpm.send(sym, *args)
  end
  
  def hash
    @checksum.hash
  end

  def eql?(other)
    @checksum == other.checksum
  end
      
  # match function at name and nvr level
  def matches(ident)
    # if the name matches, then it is sufficient
    return true if ident == @rpm.name
    # if not, compare the edition without release
    return true if ident == "#{@rpm.name}-#{@rpm.version.v}"
    # if not, compare the edition with release
    return true if ident == "#{@rpm.name}-#{@rpm.version.v}-#{@rpm.version.r}"
    # if not, also the architecture
    return true if ident == "#{@rpm.name}-#{@rpm.version.v}-#{@rpm.version.r}"
    # and finally arch
    return true if ident == "#{@rpm.name}-#{@rpm.version.v}-#{@rpm.version.r}.#{@rpm.arch}"
    return false
  end

  def to_s
    @rpm.to_s
  end

  def ident
    "#{@rpm.to_s}.#{@rpm.arch}"
  end
  
end

