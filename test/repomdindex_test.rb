$: << File.join(File.dirname(__FILE__), '..', 'lib')

require 'test/unit'
require 'enhance_repo/rpm_md/index'

class TC_RepoMdIndex < Test::Unit::TestCase

#  def assert_not_diff(one, second, message = nil)
#    
#    message = build_message message, '<?> is not false or nil.', boolean
#    assert_block message do
#      not boolean
#    end
#  end
  
  def setup
    @index = EnhanceRepo::RpmMd::Index.new
  end
  
  # def teardown
  # end

  def test_read_write
    repomdpath = File.join(TESTDATADIR, '/repomd.xml')
    index_content = File.new(repomdpath).read
    @index.read_file(File.new(repomdpath))

    # now that the file is parsed, lets test wether it
    # is parsed correctly
    assert_equal(3, @index.resources.size)
    
    dump_content = String.new
    @index.write(dump_content)
    assert_equal(index_content, dump_content, 'Reading repomd index and dumping it should not change it' )
  end
end
