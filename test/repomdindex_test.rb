#--
# 
# enhancerepo is a rpm-md repository metadata tool.
# Copyright (C) 2008, 2009 Novell Inc.
# Author: Duncan Mac-Vicar P. <dmacvicar@suse.de>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
# MA  02110-1301, USA.  A copy of the GNU General Public License is
# also available at http://www.gnu.org/copyleft/gpl.html.
#
#++
#
$: << File.join(File.dirname(__FILE__), '..', 'lib')

require 'test/unit'
require 'enhance_repo'

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
    repomdpath = test_data('repomd.xml')
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
