
module EnhanceRepo

  def self.logger
    @logger
  end

  def self.logger=(logger)
      @logger = logger
  end
  
  # provide easy access to classes to the
  # global logger
  module Logger
    def log
      EnhanceRepo.logger
    end
  end
  
end
