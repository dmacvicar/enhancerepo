
# Configuration class to hold the options
# passed from the command line to the
# components doing the work
#
class ConfigOpts
  attr_accessor :products
  attr_accessor :keywords
  attr_accessor :dir
  
  def initialize
    @products = []
    @keywords = []
  end
end
