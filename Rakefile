
require 'rake'
require 'rake/packagetask'

task :default => :test

task :test do
    require File.dirname(__FILE__) + '/test/all_tests.rb'  
end

version = File.new('VERSION').read.chomp

Rake::PackageTask.new('enhancerepo', version) do |package|
  package.need_tar_bz2 = true
  package.package_dir = "package/"
  package.package_files.include(
    '[A-Z]*',
    'lib/**',
    'lib/enhancerepo/**',
    'bin/**',
    'test/**'
  )
end