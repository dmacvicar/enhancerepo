require 'getoptlong'
require 'rdoc/usage'
require 'enhancerepo/configopts'
require 'enhancerepo/repomd'
require 'enhancerepo/constants'

opts = GetoptLong.new(
         [ '--help', '-h',     GetoptLong::NO_ARGUMENT ],
         [ '--sign', '-s',     GetoptLong::REQUIRED_ARGUMENT ],
         [ '--expire', '-e',   GetoptLong::REQUIRED_ARGUMENT ],
         [ '--updates', '-u',  GetoptLong::NO_ARGUMENT ],
         [ '--eulas', '-l',    GetoptLong::NO_ARGUMENT ],
         [ '--keywords', '-k', GetoptLong::NO_ARGUMENT ],
         [ '--disk-usage', '-d', GetoptLong::NO_ARGUMENT ],
         [ '--repo-product',   GetoptLong::REQUIRED_ARGUMENT ],
         [ '--repo-keyword',   GetoptLong::REQUIRED_ARGUMENT ],
         [ '--create-deltas',  GetoptLong::OPTIONAL_ARGUMENT ],
         [ '--deltas',  GetoptLong::NO_ARGUMENT ]             
          )

config = ConfigOpts.new

dir = nil

opts.each do |opt, arg|
  case opt
  when '--help'
    RDoc::usage
  when '--sign'
    config.signkey = arg
  when '--repo-product'
    config.repoproducts << arg
  when '--repo-keyword'
    config.repokeywords << arg
  when '--expire'
    config.expire = arg
  when '--updates'
    config.updates = true
  when '--eulas'
    config.eulas = true
  when '--keywords'
    config.keywords = true
  when '--disk-usage'
    config.diskusage = true
  when '--create-deltas'
    if arg == ''
      config.create_deltas = 1
    else
      config.create_deltas = arg.to_i
    end
  when '--deltas'
    config.deltas = true
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

# merge keywords and products to suseinfo
repomd.suseinfo.products.merge(config.repoproducts)
repomd.suseinfo.keywords.merge(config.repokeywords)

if config.eulas
  repomd.susedata.add_eulas
end

if config.keywords
  repomd.susedata.add_keywords
end

if config.diskusage
  repomd.susedata.add_disk_usage
end

if config.updates
  repomd.updateinfo.add_updates
end

if config.create_deltas
  repomd.deltainfo.create_deltas(config.create_deltas)
end

if config.deltas
    repomd.deltainfo.add_deltas
end


# add expiration date
if not config.expire.nil?
  repomd.suseinfo.expire = config.expire
end

repomd.write

if not config.signkey.nil?
  repomd.sign(config.signkey)
end
