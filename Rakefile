$: << File.join(File.dirname(__FILE__), "test")
require 'rubygems'
gem 'hoe', '>= 2.1.0'
require 'hoe'

task :default => [:docs, :test]

Hoe.plugin :yard

HOE = Hoe.spec 'enhancerepo' do
  developer('Duncan Mac-Vicar P.', 'dmacvicar@suse.de')
# s.homepage  =   "http://en.opensuse.org/Enhancerepo"
  self.summary = "Adds additional information to repomd repositories"
  self.description = "enhancerepo adds additional metadata to repommd repositories and
servers as the testbed for the specification"
  self.readme_file = ['README', ENV['HLANG'], 'rdoc'].compact.join('.')
  self.history_file = ['CHANGELOG', ENV['HLANG'], 'rdoc'].compact.join('.')
  self.extra_rdoc_files = FileList['*.rdoc']

  self.extra_deps << ['log4r', '>= 1.0.5']
  self.extra_deps << ['nokogiri', '>= 1.4']
  self.extra_deps << ['activesupport', '>= 2.3']

  self.extra_dev_deps << ['shoulda', '>= 0']
  self.extra_dev_deps << ['mocha', '>= 0']
  self.extra_dev_deps << ['yard', '>= 0']
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
