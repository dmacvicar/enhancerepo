$LOAD_PATH.push(File.join(File.dirname(__FILE__), 'lib'))
require 'bundler/gem_tasks'
require 'enhance_repo'
require 'rake/testtask'

extra_docs = ['README*', 'TODO*', 'CHANGELOG*']

task default: [:test]
Rake::TestTask.new do |t|
  t.test_files = Dir.glob(File.join(Dir.pwd, '/test/test_*.rb'))
  t.verbose = true if ENV['DEBUG']
end

begin
  require 'yard'
  YARD::Rake::YardocTask.new(:doc) do |t|
    t.files   = ['lib/**/*.rb', *extra_docs]
    t.options = ['--no-private']
  end
rescue LoadError
  STDERR.puts 'Install yard if you want prettier docs'
  require 'rdoc/task'
  Rake::RDocTask.new(:doc) do |rdoc|
    rdoc.rdoc_dir = 'doc'
    rdoc.title = "enhancerepo #{EnhanceRepo::VERSION}"
    extra_docs.each { |ex| rdoc.rdoc_files.include ex }
  end
end

desc 'Insert GPL into all source files'
task :GPL do
  gpl = File.readlines('GPL_header.txt')
  FileList['**/*.rb'].each do |filename|
    File.open(filename, 'r+') do |file|
      lines = file.readlines
      # Skip shebang line
      i = lines[0].index('#!') == 0 ? 1 : 0
      # Already have header?
      next if lines[i].index('#--') == 0

      puts "Liberating #{filename}"

      file.pos = 0
      file.print lines.insert(i, gpl).flatten
      file.truncate(file.pos)
    end
  end
end
