require 'getoptlong'
require 'rdoc/usage'
require 'enhancerepo/configopts'
require 'enhancerepo/repomd'
require 'enhancerepo/constants'

opts = GetoptLong.new(
         [ '--help', '-h', GetoptLong::NO_ARGUMENT ],
         [ '--sign', '-s', GetoptLong::REQUIRED_ARGUMENT ],
         [ '--product', '-p', GetoptLong::REQUIRED_ARGUMENT ],
         [ '--keyword', '-k', GetoptLong::REQUIRED_ARGUMENT ]             
        )

config = ConfigOpts.new

dir = nil
name = nil
repetitions = 1
sign = nil

opts.each do |opt, arg|
  case opt
  when '--help'
    RDoc::usage
  when '--sign'
    config.signkey = arg
  when '--product'
    config.products << arg
  when '--keyword'
    config.keywords << arg
  end
end

# Check if dir is given
if ARGV.length != 1
  puts "Missing dir argument (try --help)"
  exit 0
end

dir = ARGV.shift

# Check if the dir is valid
if not (File.exists?(File.join(dir + REPOMD_FILE)))
  puts "Directory '#{dir}' is not a rpm-md repository"
  exit 1
end

config.dir = dir

repomd = RepoMd.new(dir)
repomd.add_products(config.products)
repomd.add_keywords(config.keywords)
repomd.write

if not config.signkey.nil?
  repomd.sign(config.signkey)
end
