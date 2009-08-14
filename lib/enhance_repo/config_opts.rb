require 'set'

module EnhanceRepo
  
  # Configuration class to hold the options
  # passed from the command line to the
  # components doing the work
  #

  class ConfigOpts
    attr_accessor :indent
    attr_accessor :repoproducts
    attr_accessor :repokeywords
    attr_accessor :dir
    # output dir, if specified, if not
    # we use dir
    attr_writer :outputdir
    attr_accessor :signkey
    attr_accessor :expire
    attr_accessor :primary
    attr_accessor :updates
    attr_accessor :generate_update
    attr_accessor :split_updates
    attr_accessor :updatesbasedir
    attr_accessor :eulas
    attr_accessor :keywords
    attr_accessor :diskusage
    # wether to create delta rpm files
    # and how many
    attr_accessor :create_deltas
    # whether to index delta rpms
    attr_accessor :deltas
    
    def outputdir
      return @dir if @outputdir.nil?
      return @outputdir
    end
    
    def initialize
      @indent = false
      @primary = false
      @repoproducts = Set.new
      @repokeywords = Set.new
      @signkey = nil
      @updates = false
      @split_updates = false
      @eulas = false
      @keywords = false
      @diskusage = false
      @deltas = false
      @create_deltas = false
    end
  end
end
