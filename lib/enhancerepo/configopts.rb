
# Configuration class to hold the options
# passed from the command line to the
# components doing the work
#
class ConfigOpts
  attr_accessor :products
  attr_accessor :keywords
  attr_accessor :dir
  attr_accessor :signkey
  
  def initialize
    @products = []
    @keywords = []
    @signkey = nil
  end
end
