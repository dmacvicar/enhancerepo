
require 'rubygems'
require 'builder'

# represents SUSE extensions to repository
# metadata (not associated with packages)
#
# See:
# http://en.opensuse.org/Standards/Rpm_Metadata#SUSE_repository_info_.28suseinfo.xml.29
#
class SuseInfo

  # expiration time
  # the generated value is
  # still calculated from repomd.xml
  # resources
  attr_accessor :expire
  attr_accessor :products
  attr_accessor :keywords
  
  def initialize(dir)
    @dir = dir
    @keywords = Set.new
    @products = Set.new
  end

  def empty?
    @expire.nil? and @products.empty? and @keywords.empty?
  end
  
  def write(file)
    builder = Builder::XmlMarkup.new(:target=>file, :indent=>2)
    builder.instruct!
    xml = builder.suseinfo do |b|

      # add expire tag
      b.expire(@expire.to_i.to_s)

      if not @keywords.empty?
        b.keywords do |b|
          @keywords.each do |k|
            b.k(k)
          end
        end
      end

      if not @products.empty?
        b.products do |b|
          @products.each do |p|
            b.id(p)
          end
        end
      end

    end
  end
end
