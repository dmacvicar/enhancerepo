require 'rake'
require 'rake/gempackagetask'
require 'rake/packagetask'

task :default => :test

task :test do
    require File.dirname(__FILE__) + '/test/all_tests.rb'  
end

version = File.new('VERSION').read.chomp

spec = Gem::Specification.new do |s|
    s.platform  =   Gem::Platform::RUBY
    s.name      =   "enhancerepo"
    s.version   =   "0.4"
    s.author    =   "Duncan Mac-Vicar P."
    s.email     =   "dmacvicar@suse.de"
    s.homepage  =   "http://en.opensuse.org/Enhancerepo"
    s.summary   =   "Adds additional information to repomd repositories"
    s.description = "enhancerepo adds additional metadata to repommd repositories and
servers as the testbed for the specification"
    s.files     =   FileList['lib/**/*.rb', 'test/*', 'bin/enhancerepo'].to_a
    s.require_path  =   "lib"
    s.test_files = Dir.glob('tests/*.rb')
    s.has_rdoc  =  true
#    s.extra_rdoc_files  =   ["README"]
end

Rake::GemPackageTask.new(spec) do |pkg|
    pkg.need_tar = true
end
