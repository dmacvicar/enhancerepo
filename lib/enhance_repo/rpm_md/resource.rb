
module EnhanceRepo
  module RpmMd

    # represents a resource in repomd.xml
    class Resource
      attr_accessor :type
      attr_accessor :location, :checksum, :timestamp, :openchecksum

      # define equality based on the location
      # as it has no sense to have two resources for the
      #same location
      def ==(other)
        return (location == other.location) if other.is_a?(Resource)
        false
      end      
    end
    
  end
end
