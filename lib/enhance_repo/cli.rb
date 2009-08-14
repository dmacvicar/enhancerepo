require 'rubygems'
require 'getoptlong'
require 'rdoc/usage'
require 'enhance_repo/config_opts'
require 'enhance_repo/rpm_md/repo'
require 'enhance_repo/constants'
require 'pathname'
require 'log4r'

include Log4r

log = Logger.new 'enhancerepo'
log.level = INFO
console_format = PatternFormatter.new(:pattern => "%l:\t %m")
log.add Log4r::StdoutOutputter.new('console', :formatter=>console_format)

opts = GetoptLong.new(
         [ '--help', '-h',     GetoptLong::NO_ARGUMENT ],
         [ '--outputdir', '-o',     GetoptLong::REQUIRED_ARGUMENT ],
         [ '--primary', '-p',  GetoptLong::NO_ARGUMENT ],
         [ '--indent', '-i',     GetoptLong::OPTIONAL_ARGUMENT ],
         [ '--sign', '-s',     GetoptLong::REQUIRED_ARGUMENT ],
         [ '--expire', '-e',   GetoptLong::REQUIRED_ARGUMENT ],
         [ '--updates', '-u',  GetoptLong::NO_ARGUMENT ],
         [ '--generate-update', GetoptLong::REQUIRED_ARGUMENT ],
         [ '--split-updates', GetoptLong::NO_ARGUMENT ],
         [ '--updates-base-dir', GetoptLong::REQUIRED_ARGUMENT ],
         [ '--eulas', '-l',    GetoptLong::NO_ARGUMENT ],
         [ '--keywords', '-k', GetoptLong::NO_ARGUMENT ],
         [ '--disk-usage', '-d', GetoptLong::NO_ARGUMENT ],
         [ '--repo-product',   GetoptLong::REQUIRED_ARGUMENT ],
         [ '--repo-keyword',   GetoptLong::REQUIRED_ARGUMENT ],
         [ '--create-deltas',  GetoptLong::OPTIONAL_ARGUMENT ],
         [ '--deltas',  GetoptLong::NO_ARGUMENT ],
         [ '--debug',  GetoptLong::NO_ARGUMENT ]             
)

config = EnhanceRepo::ConfigOpts.new

dir = nil

opts.each do |opt, arg|
  case opt
  when '--help'
    RDoc::usage
  when '--outputdir'
    config.outputdir = Pathname.new(arg)
  when '--primary'
    config.indent = true
  when '--indent'
    config.primary = true
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
  when '--generate-update'
    packages = arg.split(",")
    config.generate_update = packages
  when '--split-updates'
    config.split_updates = true
  when '--updates-base-dir'
    config.updatesbasedir = Pathname.new(arg)
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
  when '--debug'
    log.level = DEBUG
  end
end

# Check if dir is given
if ARGV.length != 1
  log.fatal "Missing dir argument (try --help)"
  exit 0
end

dir = ARGV.shift

# Check if the dir is valid
#if not (File.exists?(File.join(dir + REPOMD_FILE)))
#  puts "Directory '#{dir}' is not a rpm-md repository"
#  exit 1
#end

config.dir = Pathname.new(dir)

repomd = EnhanceRepo::RpmMd::Repo.new(log, config)

# perform the operations in a rescue block

begin
  if config.primary
    repomd.primary.read
    repomd.filelists.read
    repomd.other.read
    #repomd.primary.read
  end

  # merge keywords and products to suseinfo
  repomd.suseinfo.products.merge(config.repoproducts)
  repomd.suseinfo.keywords.merge(config.repokeywords)

  repomd.susedata.add_eulas if config.eulas  
  repomd.susedata.add_keywords if config.keywords
  repomd.susedata.add_disk_usage if config.diskusage

  if not config.generate_update.nil?
    # make sure the repoparts directory is there
    `mkdir -p #{File.join(config.dir, 'repoparts')}`
    repomd.updateinfo.generate_update(config.generate_update, File.join(config.dir, 'repoparts') )
  end

  repomd.updateinfo.add_updates if config.updates  
  repomd.updateinfo.split_updates(File.join(config.dir, 'repoparts')) if config.split_updates                                                                        

  repomd.deltainfo.create_deltas(config.create_deltas) if config.create_deltas
  repomd.deltainfo.add_deltas if config.deltas
    
  # add expiration date
  repomd.suseinfo.expire = config.expire if not config.expire.nil?

  # write the repository out
  repomd.write

  # perform signature of the repository
  repomd.sign(config.signkey) if not config.signkey.nil?  
rescue Exception => excp
  log.fatal excp.message
end
