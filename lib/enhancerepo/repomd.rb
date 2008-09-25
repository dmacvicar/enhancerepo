require 'rubygems'
require 'builder'
require 'rexml/document'
require 'digest/sha1'
require 'enhancerepo/constants'
require 'zlib'
require 'yaml'

require 'enhancerepo/packageid'
require 'enhancerepo/rpmmd/updateinfo'
require 'enhancerepo/rpmmd/suseinfo'
require 'enhancerepo/rpmmd/susedata'

include REXML

# represents a resource in repomd.xml
class RepoMdResource
  attr_accessor :type
  attr_accessor :location, :checksum, :timestamp, :openchecksum

  # define equality based on the location
  # as it has no sense to have two resources for the
  #same location
  def ==(other)
    return (location == other.location) if other.is_a?(RepoMdResource)
    false
  end
  
end

# represents the repomd index
class RepoMdIndex
  attr_accessor :products, :keywords

  # constructor
  # repomd - repository
  def initialize
    @resources = []
  end

  # add a file resource. Takes care of setting
  # all the metadata.
  
  def add_file_resource(abspath, path, type=nil)
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
      STDERR.puts("#{r.location} already exists. Replacing.")
      @resources[index] = r
    end
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

class RepoMd

  attr_accessor :index

  # extensions
  attr_reader :susedata, :suseinfo
  
  def initialize(dir)
    @index = RepoMdIndex.new
    # populate the index
    @index.read_file(File.new(File.join(dir, REPOMD_FILE)))    
    @dir = dir
    @susedata = SuseData.new(dir)
    @updateinfo = UpdateInfo.new(dir)
    @suseinfo = SuseInfo.new(dir)
  end

  def sign(keyid)
    # check if the index is written to disk
    repomdfile = File.join(@dir, REPOMD_FILE)
    if not File.exists?(repomdfile)
      raise "#{repomdfile} does not exist."
    end
    # call gpg to sign the repository
    `gpg -sab -u #{keyid} -o #{repomdfile}.asc #{repomdfile}`
    if not File.exists?("#{repomdfile}.asc")
      STDERR.puts "Could't not generate signature #{repomdfile}.asc"
      exit(1)
    else
      STDERR.puts "#{repomdfile}.asc signature generated"
    end

    # now export the public key
    `gpg --export -a -o #{repomdfile}.key #{keyid}`

    if not File.exists?("#{repomdfile}.key")
      STDERR.puts "Could't not generate public key #{repomdfile}.key"
      exit(1)
    else
      STDERR.puts "#{repomdfile}.key public key generated"
    end
  end

  # write back the metadata
  def write
    repomdfile = File.join(@dir, REPOMD_FILE)
    susedfile = "#{File.join(@dir, SUSEDATA_FILE)}.gz"
    updateinfofile = "#{File.join(@dir, UPDATEINFO_FILE)}.gz"
    suseinfofile = "#{File.join(@dir, SUSEINFO_FILE)}.gz"
   
    write_gz_extension_file(@updateinfo, updateinfofile, UPDATEINFO_FILE)
    write_gz_extension_file(@susedata, susedfile, SUSEDATA_FILE)
    write_gz_extension_file(@suseinfo, suseinfofile, SUSEINFO_FILE)
    
    # now write the index
    f = File.open(File.join(@dir, REPOMD_FILE), 'w')
    STDERR.puts "Saving #{repomdfile} .."
    @index.write(f)
    
  end

  # writes an extension to an xml filename if
  # the extension is not empty
  def write_gz_extension_file(extension, filename, relfilename)
    if not extension.empty?
      repomdfile = File.join(@dir, REPOMD_FILE)
      STDERR.puts "Saving #{filename} .."
      f = File.open(filename, 'w')
      # compress the output
      gz = Zlib::GzipWriter.new(f)
      extension.write(gz)
      gz.close
      # add it to the index
      STDERR.puts "Adding #{filename} to #{repomdfile} index"
      @index.add_file_resource("#{relfilename}.gz", filename)
    end
  end
  
end
