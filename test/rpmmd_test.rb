$: << File.join(File.dirname(__FILE__), '..', 'lib')

require 'tmpdir'
require 'test/unit'
require 'pathname'
require 'rubygems'
require 'log4r'
require 'enhance_repo'
require 'stringio'

include Log4r

class RpmMd_test < Test::Unit::TestCase

  def setup
    rpms = Pathname.new(File.join(File.dirname(__FILE__), 'data', 'rpms'))
    @rpms1 = rpms + 'update-test-11.1'
    @rpms3 = rpms + 'update-test-factory'

    @log = Logger.new 'enhancerepo'
    @log.level = INFO
    console_format = PatternFormatter.new(:pattern => "%l:\t %m")
    @log.add Log4r::StdoutOutputter.new('console', :formatter=>console_format)
  end
  
  # def teardown
  # end

  def test_disk_info
    config = EnhanceRepo::ConfigOpts.new
    config.outputdir = Pathname.new(File.join(Dir.tmpdir, 'enhancerepo#{Time.now.to_i}'))
    config.dir = @rpms1
    @repo = EnhanceRepo::RpmMd::Repo.new(@log, config)
    @repo.primary.read
    out = StringIO.new
    @repo.primary.write(out)
    #puts out.string
    
  end

  def test_update_info
    #config.generate_update = packages
  end
  
end
