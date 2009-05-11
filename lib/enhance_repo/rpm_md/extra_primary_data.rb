
require 'rubygems'
require 'builder'

module EnhanceRepo
  module RpmMd

    # represents a set non standard data tags
    # but it is not part of the standard, yet still associated
    # with a particular package (so with primary.xml semantics
    class ExtraPrimaryData
      # initialize the extra data with a name
      def initialize(name)
        @name = name
      end
    end
    
  end
end
