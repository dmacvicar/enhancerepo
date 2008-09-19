# == Synopsis
#
# enhancerepo: adds extra data to a repomd repository
#
# == Usage
#
# enhancerepo [OPTION] ... DIR
#
# -h, --help:
#    show help
#
# --repeat x, -n x:
#    repeat x times
#
# --name [name]:
#    greet user by name, if name not supplied default is John
#
# DIR: The repo base directory ( where repodata/ directory is located )

require 'getoptlong'
require 'rdoc/usage'
require 'enhancerepo/configopts'
require 'enhancerepo/repomd'
require 'enhancerepo/constants'

opts = GetoptLong.new(
         [ '--help', '-h', GetoptLong::NO_ARGUMENT ],
         [ '--product', '-p', GetoptLong::REQUIRED_ARGUMENT ],
         [ '--keyword', '-k', GetoptLong::REQUIRED_ARGUMENT ]             
        )

config = ConfigOpts.new

dir = nil
name = nil
repetitions = 1

opts.each do |opt, arg|
  case opt
  when '--help'
    RDoc::usage
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
repomd.write($stdout)


