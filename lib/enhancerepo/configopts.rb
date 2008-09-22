
# Configuration class to hold the options
# passed from the command line to the
# components doing the work
#
class ConfigOpts
  attr_accessor :products
  attr_accessor :keywords
  attr_accessor :dir
  attr_accessor :signkey
  attr_accessor :expire
  attr_accessor :updates
  attr_accessor :eulas
  
  def initialize
    @products = Set.new
    @keywords = Set.new
    @signkey = nil
    @updates = false
    @eulas = false
  end
end
