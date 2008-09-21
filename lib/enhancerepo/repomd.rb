require 'rubygems'
require 'builder'
require 'rexml/document'
require 'digest/sha1'
require 'enhancerepo/constants'
require 'zlib'

include REXML

# represents a resource in repomd.xml
class RepoMdResource
  attr_accessor :type
  attr_accessor :location, :checksum, :timestamp, :openchecksum
end

# represents the repomd index
class RepoMdIndex
  attr_accessor :resources
  attr_accessor :products, :keywords

  # constructor
  def initialize
    @resources = []
    @products = Set.new
    @keywords = Set.new
  end

  # add a resource from physical file
  # if the type is not given, then it
  # is figured out from the filename
  def add_file_resource(path, type=nil)
    r = RepoMdResource.new
    r.type = type
    # figure out the type of resource
    r.type = File.basename(path, File.extname(path)) if r.type.nil?
    r.location = path
    r.checksum = Digest::SHA1.hexdigest(path)
    r.openchecksum = r.checksum
    r.timestamp = File.mtime(path).to_s
  end

  def add_file_resource(path, type=nil)
    r = RepoMdResource.new
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
    r.location = path
    r.timestamp = File.mtime(path).to_s
    r.checksum = Digest::SHA1.hexdigest(File.new(path).read)
    r.openchecksum = r.checksum
    if File.extname(path) == '.gz'
      # we have a different openchecksum
      r.openchecksum = Digest::SHA1.hexdigest(Zlib::GzipReader.new(File.new(path)).read)
    end
    @resources << r
  end

  
  # read data from a file
  def read_file(file)
    doc = Document.new(file)
    doc.elements.each('repomd/data') do |datael|
      resource = RepoMdResource.new
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
      @resources << resource
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

      # only add the metadata tag if there are products or keywords
      if has_metadata?
        b.metadata do |b|
          # only show product tag if there are products
          if not @products.empty?
            b.products do |b|
              @products.each do |product|
                b.id product
              end
            end
          end
          # only show keyword tags if there are keywords
          if not @keywords.empty?
            b.keywords do |b|
             @keywords.each do |keyword|
                b.k keyword
              end
            end
          end
          # done with metadata
        end #close metadata tag
      end # has_metadata?
    end #builder
    
  end
  
  # true if the index has metadata (non standard)
  # like products, keywords, etc
  def has_metadata?
    return !@products.empty? || !@keywords.empty?
  end
  
end

class PackageId
  attr_accessor :name, :version, :release, :arch, :epoch
  attr_accessor :checksum

  def initialize(rpmfile)
    STDERR.puts "Reading #{rpmfile} information..."
    @name, @arch, @version, @epoch, @release, @checksum = `rpm -qp --queryformat "%{NAME} %{ARCH} %{VERSION} %{EPOCH} %{RELEASE}" #{rpmfile}`.split(' ')
    @checksum = Digest::SHA1.hexdigest(File.new(rpmfile).read)
  end
  
  def eql(other)
      return checksum.eql?(other.checksum)
  end

  def hash
    checksum
  end

  def to_s
    "#{name}-#{version}-#{release}-#{arch}(#{checksum})"
  end
end

# represents a set non standard data tags
# but it is not part of the standard, yet still associated
# with a particular package (so with primary.xml semantics
class ExtraPrimaryData
  # initialize the extra data with a name
  def initialize(name)
    @name = name
    # the following hash automatically creates a sub
    # hash for non found values
    @properties = Hash.new { |h,v| h[v]= Hash.new }

  end

  # add an attribute named name for a
  # package identified with pkgid
  def add_attribute(pkgid, name, value)
    @properties[pkgid][name] = value
  end

  def empty?
    @properties.empty?
  end
  
  def write(file)
    builder = Builder::XmlMarkup.new(:target=>file, :indent=>2)
    builder.instruct!
    xml = builder.tag!(@name) do |b|
      @properties.each do |pkgid, props|
        b.package('pkgid' => pkgid.checksum, 'name' => pkgid.name) do |b|
          b.version('ver' => pkgid.version, 'rel' => pkgid.release, 'arch' => pkgid.arch, 'epoch' => 0.to_s )
          props.each do |propname, propvalue|
            b.tag!(propname, propvalue)
          end
        end # end package tag
      end # iterate over properties
    end #done builder
  end
  
end

class SuseData < ExtraPrimaryData

  def initialize(dir)
    super('susedata')
    @dir = dir
  end

  def add_eulas
    # add eulas
    Dir["#{@dir}/**/*.eula"].each do |eulafile|
      base = File.basename(eulafile, '.eula')
      # =>  look for all rpms with that name in that dir
      Dir["#{File.dirname(eulafile)}/#{base}*.rpm"].each do | rpmfile |
        pkgid = PackageId.new(rpmfile)
        if base == pkgid.name
          eulacontent = File.new(eulafile).read
          add_attribute(pkgid, 'eula', eulacontent)
          STDERR.puts "Adding eula: #{eulafile.to_s}"
        else
          STDERR.puts "discarding eula #{eulafile} : #{pkgid.to_s}"
        end
      end
    end
    # end of directory iteration
  end
  
end

class RepoMd

  attr_accessor :index
  
  def initialize(dir)
    @index = RepoMdIndex.new
    # populate the index
    @index.read_file(File.new(File.join(dir, REPOMD_FILE)))    
    @dir = dir
    @susedata = SuseData.new(dir)
    @susedata.add_eulas
  end

  # add supported products to the
  # repository metadata
  def add_products(products)
    products.each do |p|
      @index.products.add p
    end
  end

  # add keywords to the repository
  # metadata
  def add_keywords(keywords)   
    keywords.each do |k|
      @index.keywords.add k
    end
  end
  
  def write
    repomdfile = File.join(@dir, REPOMD_FILE)
    susedfile = "#{File.join(@dir, SUSEDATA_FILE)}.gz"
   
    if not @susedata.empty?
      STDERR.puts "Saving #{susedfile} .."
      f = File.open(susedfile, 'w')
      # compress the output
      gz = Zlib::GzipWriter.new(f)
      @susedata.write(gz)
      gz.close
      # add it to the index
      STDERR.puts "Adding #{susedfile} to #{repomdfile} index"
      @index.add_file_resource(susedfile)
    end

    # now write the index
    f = File.open(File.join(@dir, REPOMD_FILE), 'w')
    STDERR.puts "Saving #{repomdfile} .."
    @index.write(f)
    
  end  
end
