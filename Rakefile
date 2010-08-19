require "rake"
require "rake/rdoctask"
require "rake/testtask"

$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
require "enhance_repo/version"

task :build do
  system "gem build enhancerepo.gemspec"
end

task :install => :build do
  system "sudo gem install enhancerepo-#{EnhanceRepo::VERSION}.gem"
end

Rake::TestTask.new do |t|
  t.libs << File.expand_path('../test', __FILE__)
  t.libs << File.expand_path('../', __FILE__)
  t.test_files = FileList['test/test*.rb']
  t.verbose = true
end

extra_docs = ['README*', 'TODO*', 'CHANGELOG*']

begin
 require 'yard'
  YARD::Rake::YardocTask.new(:doc) do |t|
    t.files   = ['lib/**/*.rb', *extra_docs]
  end
rescue LoadError
  STDERR.puts "Install yard if you want prettier docs"
  Rake::RDocTask.new(:doc) do |rdoc|
    if File.exist?("VERSION.yml")
      config = File.read("VERSION")
      version = "#{config[:major]}.#{config[:minor]}.#{config[:patch]}"
    else
      version = ""
    end
    rdoc.rdoc_dir = "doc"
    rdoc.title = "enhancerepo #{version}"
    extra_docs.each { |ex| rdoc.rdoc_files.include ex }
  end
end

task :default => ["test"]


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
