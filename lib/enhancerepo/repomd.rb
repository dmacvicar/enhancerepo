require 'rexml/document'
require 'enhancerepo/constants'

include REXML

class ExtraPrimaryData
  attr_accessor :name, :version, :release, :arch, :epoch
  attr_accessor :sha1header  
end

class EulaData < ExtraPrimaryData
  attr_accessor :eulafile

  def to_s
    return "#{name}-#{version}-#{arch} :#{sha1header} -> #{eulafile}"
  end
end

class RepoMd

  def initialize(dir)
    # open the repomd.xml file
    @dir = dir
    # parse it as a DOM
    @doc = Document.new(File.new(File.join(dir, REPOMD_FILE)).read)
    @products = Set.new
    @keywords = Set.new
    @eulas = Array.new
  end

  # add supported products to the
  # repository metadata
  def add_products(products)
    products.each do |p|
      @products.add p
    end
  end

  # add keywords to the repository
  # metadata
  def add_keywords(keywords)   
    keywords.each do |k|
      @keywords.add k
    end
  end

  def add_suse_data
    # add eulas
    Dir["#{@dir}/**/*.eula"].each do |eulafile|
      base = File.basename(eulafile, '.eula')
      # look for all rpms with that name in that dir
      Dir["#{File.dirname(eulafile)}/#{base}*.rpm"].each do | rpmfile |
        eula = EulaData.new
        
        eula.name, eula.arch, eula.version, eula.epoch, eula.release, eula.sha1header = `rpm -qp --queryformat "%{NAME} %{ARCH} %{VERSION} %{EPOCH} %{RELEASE} %{SHA1HEADER}" #{rpmfile}`.split(' ')
        if base == eula.name
          eula.eulafile = eulafile
          STDERR.puts "Adding eula: #{eula.to_s}"
          @eulas << eula
        end
      end
    end
  end

  # dump suse specific data to io
  def dump_suse_data(io)
    doc = Document.new
    doc << XMLDecl.new

    susedata = Element.new('susedata')
    doc.elements << susedata
    @eulas.each do |eula|
      package = Element.new('package')
      package.attributes['pkgid'] = eula.sha1header
      package.attributes['name'] = eula.name

      # rpmmd oddity
      verel = Element.new('version')
      
      verel.attributes['ver'] = eula.version
      verel.attributes['rel'] = eula.release
      verel.attributes['name'] = eula.arch
      verel.attributes['epoch'] = 0.to_s

      package.elements << verel
      
      eulael = Element.new('eula')
      eulael.text = File.new(eula.eulafile).read
      package.elements << eulael
      susedata.elements << package
    end
    doc.write(io)
  end
  
  # merge the extra data in the dom tree
  def add_repomd_data

    if repomd_index_metadata?
      # add extra metadata
      metadata = Element.new('metadata')
      repomd = @doc.elements[1]
      repomd.elements << metadata
      if not @products.empty?
        products = Element.new('products')
        metadata.elements << products
        @products.each do | p |
          product = Element.new('id')
          product.text = p
          products << product
        end
      end
      if not @keywords.empty?
        keywords = Element.new('keywords')
        metadata.elements << keywords
        @keywords.each do | k |
          keyword = Element.new('k')
          keyword.text = k
          keywords << keyword
        end
      end
    end

  end

  def dump_repomd_data(io)
    @doc.write(io)
  end

  def repomd_index_metadata?
    return (! @products.empty?) || ( ! @keywords.empty?)
  end
  
  def suse_data?
    return (! @eulas.empty?)
  end
  
  def write
    repomdfile = File.join(@dir, REPOMD_FILE)
    susedfile = File.join(@dir, SUSEDATA_FILE)
   
    add_repomd_data

    f = File.open(File.join(@dir, REPOMD_FILE), 'w')
    STDERR.puts "Saving #{repomdfile} .."
    dump_repomd_data(f)

    add_suse_data

    if suse_data?
      STDERR.puts "Saving #{susedfile} .."
      f = File.open(File.join(@dir, SUSEDATA_FILE), 'w')
      dump_suse_data(f)
    end
    # add susedata.xml to index if needed
    if suse_data?
      STDERR.puts "Adding #{susedfile} to #{repomdfile} index"
      `modifyrepo #{susedfile} #{File.join(@dir, '/repodata')}`
    end

  end  
end
