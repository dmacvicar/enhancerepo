require 'rexml/document'
require 'enhancerepo/constants'

include REXML

class RepoMd

  def initialize(dir)
    # open the repomd.xml file
    f = File.new(File.join(dir, REPOMD_FILE))
    # parse it as a DOM
    @doc = Document.new(f)
    @products = Set.new
    @keywords = Set.new
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
  
  # merge the extra data in the dom tree
  def merge_extra_data
    metadata_available = (not @products.empty?) or
                         (not @keywords.empty?)    
    if metadata_available
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
  
  def write(io)
    merge_extra_data
    @doc.write(io)
  end

  def to_s
    merge_extra_data
    @doc.to_s
  end
end
