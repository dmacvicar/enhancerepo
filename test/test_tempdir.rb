# Encoding: utf-8
#
# Author::    Yuichi Tateno <hotchpotch@gmail.com>
# Copyright:: Copyright (c) 2008 Yuichi Tateno
# License::   MIT

require File.dirname(__FILE__) + '/test_helper.rb'

require "test/unit"
require "tempdir"
require "tempdir/tempfile"

class TempdirTest < Test::Unit::TestCase
  def test_open
    _dir = nil
    Tempdir.open do |dir|
      assert dir.directory?
      assert_equal dir.class, Pathname
      _dir = dir.clone
    end
    assert !_dir.directory?
  end

  def test_tempdir
    begin
      assert_equal Tempdir.tmpdir.to_s, Dir.tmpdir.to_s
      Tempdir.tmpdir = Dir.tmpdir + '/foobar'
      assert_equal Tempdir.tmpdir.to_s, Pathname.new(Dir.tmpdir + '/foobar').to_s
    ensure
      Tempdir.tmpdir = Dir.tmpdir
    end
  end

  def test_new
    tmpdir = Tempdir.new
    assert tmpdir.dir.directory?
    _dir = tmpdir.dir.clone
    tmpdir.close
    assert !_dir.directory?
  end

  def test_open_with_name
    _dir = nil
    Tempdir.open('adfklvucoiae89u893qakj') do |dir|
      assert dir.directory?
      _dir = dir.clone
    end
    assert !_dir.directory?
  end

  def test_new_with_name
    tmpdir = Tempdir.new('asdfkjvijoaeeeeeegvafkldj12839uy')
    assert tmpdir.dir.directory?
    _dir = tmpdir.dir.clone
    tmpdir.close
    assert !_dir.directory?
  end

  def test_tempfile
    Tempdir::Tempfile.open do|f|
      assert f
    end
  end
end
