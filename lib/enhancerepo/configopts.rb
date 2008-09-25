
# Configuration class to hold the options
# passed from the command line to the
# components doing the work
#
class ConfigOpts
  attr_accessor :repoproducts
  attr_accessor :repokeywords
  attr_accessor :dir
  attr_accessor :signkey
  attr_accessor :expire
  attr_accessor :updates
  attr_accessor :eulas
  attr_accessor :keywords
  attr_accessor :diskusage
  
  def initialize
    @repoproducts = Set.new
    @repokeywords = Set.new
    @signkey = nil
    @updates = false
    @eulas = false
    @keywords = false
    @diskusage = false
  end
end