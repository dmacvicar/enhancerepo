
require 'rubygems'
require 'builder'
require 'rexml/document'
require 'yaml'

include REXML

class Reference
  attr_accessor :href
  attr_accessor :referenceid
  attr_accessor :title
  attr_accessor :type

  def initialize
    @href = "http://bugzilla.novell.com"
    @referenceid = "none"
    @title = ""
    @type = "bugzilla"
  end
end

class Update
  attr_accessor :updateid
  attr_accessor :status
  attr_accessor :from
  attr_accessor :type
  attr_accessor :version
  attr_accessor :release
  attr_accessor :issued
  attr_accessor :references
  attr_accessor :description
  attr_accessor :title

  attr_accessor :packages
  
  def initialize
    # some default sane values
    @updateid = "update"
    @status = "stable"
    @from = "#{ENV['USER']}@#{ENV['HOST']}"
    @type = "optional"
    @version = "1"
    @release = "no release"
    @issued = Time.now.to_i
    @references = []
    @description = ""
    @title = "Untitled update"
    @packages = []
  end

  # automatically set empty fields
  # needs the description to be set to
  # be somehow smart
  def smart_fill_blank_fields
    # figure out the type (optional is default)
    if description =~ /vulnerability|security|CVE|Secunia/
      @type = 'security'
    else
      @type = 'recommended' if description =~ /fix|bnc#|bug|crash/
    end

    @title << "#{@type} update #{@version}"
    
    # now figure out the title
    # if there is only package
    if @packages.size == 1
      # then name the fix according to the package, and the type
      @title << "for #{@packages.first.name}"
      @id = @packages.first.name
    elsif @packages.size < 1
      # do nothing, it is may be just a message
    else
      # figure out what the multiple packages are
      if @packages.grep(/kde/).size > 1
        # assume it is a KDE update
        @title << "for KDE"
        # KDE 3 or KDE4
        @id = "KDE3" if @packages.grep(/kde(.+)3$/).size > 1
        @id = "KDE4" if @packages.grep(/kde(.+)4$/).size > 1
      elsif @packages.grep(/kernel/).size > 1
        @title << "for the Linux kernel"
        @id = 'kernel'
      end
    end
    # now figure out and fill references
    bugzillas = description.scan(/bnc#(\d+)/)
    bugzillas.each do |bnc|
      ref = Reference.new
      ref.href << "/#{bnc}"
      ref.referenceid = bnc
      ref.title = "bug number #{bnc}"
      @references << ref
    end
  end
  
  # write a update out
  def write(file)
    builder = Builder::XmlMarkup.new(:target=>file, :indent=>2)
    append_to_builder(builder)
  end
  
  def append_to_builder(builder)  
    builder.update('status' => 'stable', 'from' => @from, 'version' => @version, 'type' => @type) do |b|
      b.title(@title)
      b.id(@id)
      b.issued(@issued)
      b.release(@release)
      b.description(@description)
        # serialize attr_reader :eferences
      b.references do |b|
        @references.each do |r|
          b.reference('href' => r.href, 'id' => r.referenceid, 'title' => r.title, 'type' => r.type )   
        end
      end
      # done with references
      b.pkglist do |b|
        b.collection do |b|
          @packages.each do |pkg|
            b.package('name' => pkg.name, 'arch'=> pkg.arch, 'version'=>pkg.version.v, 'release'=>pkg.version.r) do |b|
              b.filename(File.basename(pkg.path))
            end
          end
        end # </collection>
      end #</pkglist>
      # done with the packagelist
    end
  end
  
end

class UpdateInfo

  def initialize(dir)
    @dir = dir
    @updates = Array.new
  end

  def empty?
    return @updates.empty?
  end
  
  def add_updates
    Dir["#{@dir}/**/*.update"].each do |updatefile|
      node = YAML.load(File.new(updatefile).read)
      STDERR.puts("Adding update #{updatefile}")
      @nodes << node
    end
    # end of directory iteration
  end

  # generates a patch from a list of package names
  # it compares the last version of those package names
  # with their previous ones
  #
  def generate_update(packages)
    # make a hash name -> array of packages
    STDERR.puts "generating update..."
    pkgs = Hash.new    
    Dir["#{@dir}/**/*.rpm"].each do |rpmfile|
      next if rpmfile =~ /\.delta\.rpm$/
      rpm = PackageId.new(rpmfile)     
      pkgs[rpm.name] = Array.new if not pkgs.has_key?(rpm.name)
      pkgs[rpm.name] << rpm
    end

    # do our package hash include every package?
    packages.each do |pkg|
      if not pkgs.has_key?(pkg)
        STDERR.puts "the package '#{pkg}' is not available in the repository."
      end
    end

    update = Update.new
    
    packages.each do |pkgname|
      pkglist = pkgs[pkgname]
      STDERR.puts "#{pkglist.size} versions for '#{pkgname}'"
      # sort them by version
      pkglist.sort! { |a,b| a.version <=> b.version }
      pkglist.reverse!
      # now that the list is sorted, the new rpm is the first

      # if there is only one package then we don't need changelog
      if pkglist.size > 1
        first = pkglist.shift
        second = pkglist.shift
        # go down old version until there is some different package
        while (diff = first.changelog[0, first.changelog.size - second.changelog.size]).empty?
          second = pkglist.shift
        end
        STDERR.puts "Found change #{first.ident} and #{second.ident}."
        
        STDERR.puts "'#{pkgname}' has #{diff.size} entries (#{first.changelog.size}/#{second.changelog.size})"
        update.packages << first
        diff.each do |entry|
          update.description << entry.text << "\n"
        end
      else
        raise "ah"
      end
    
    end
    # before writing the update, figure out more
    # information
    update.smart_fill_blank_fields
    update.write(STDOUT)
  end
  
  # write a update out
  def write(file)
    builder = Builder::XmlMarkup.new(:target=>file, :indent=>2)
    builder.instruct!
    xml = builder.updates do |b|
      @updates.each do |update|
        update.append_to_builder(b)
      end
    end #done builder
  end
  
end

