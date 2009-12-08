require 'rake'
require 'rake/gempackagetask'
require 'rake/packagetask'
require 'rake/testtask'

task :default => :test

Rake::TestTask.new do |t|
  t.test_files = FileList['test/*_test.rb']
  t.verbose = true
  t.warning = true
end

version = File.new('VERSION').read.chomp

spec = Gem::Specification.new do |s|
    s.platform  =   Gem::Platform::RUBY
    s.name      =   "enhancerepo"
    s.version   =   "0.4.0"
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
    s.add_dependency('log4r', '>= 1.0.5')
    s.add_dependency('nokogiri', '>= 1.4')
    s.add_dependency('actvesupport', '>= 2.3')
#    s.extra_rdoc_files  =   ["README"]
end

Rake::GemPackageTask.new(spec) do |pkg|
    pkg.need_tar = true
end

desc "Insert GPL into all source files"
task :GPL do
  gpl = File.readlines('GPL_header.txt')
  FileList['**/*.rb'].each do |filename|
    File.open(filename, 'r+') do |file|
      lines = file.readlines      
      # Skip shebang line
      i = (lines[0].index('#!') == 0) ? 1 : 0
      # Already have header?
      next if lines[i].index('#--') == 0
      
      puts "Liberating #{filename}"
      
      file.pos = 0
      file.print lines.insert(i, gpl).flatten
      file.truncate(file.pos)
    end
  end
end
