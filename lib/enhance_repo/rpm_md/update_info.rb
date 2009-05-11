
require 'rubygems'
require 'builder'
require 'rexml/document'
require 'yaml'
require 'prettyprint'

module EnhanceRepo
  module RpmMd

    include REXML

    #
    # Represents a reference to a external bugreport
    # feature or issue for a software update
    #
    class Reference
      # uri of the reference
      attr_accessor :href
      # its type, for example, bnc (novell's bugzilla)
      attr_accessor :type
      # the id, for example 34561
      # the pair type-id should be globally unique
      attr_accessor :referenceid
      # label to display to the user
      attr_accessor :title

      # initialize a reference, per default a novell
      # bugzilla type
      def initialize
        @href = "http://bugzilla.novell.com"
        @referenceid = "none"
        @title = ""
        @type = "bugzilla"
      end
    end

    # represents one update, which can consist of various packages
    # and references
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
        @updateid = "unknown"
        @status = "stable"
        @from = "#{ENV['USER']}@#{ENV['HOST']}"
        @type = "optional"
        @version = 1
        @release = "no release"
        @issued = Time.now.to_i
        @references = []
        @description = ""
        @title = "Untitled update"
        @packages = []
      end

      # an update is not empty if it
      # updates something
      def empty?
        @packages.empty?
      end

      def suggested_filename
        "update-#{@updateid}-#{@version}"
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

        @title << "#{@type} update #{@version} "
        
        # now figure out the title
        # if there is only package
        if @packages.size == 1
          # then name the fix according to the package, and the type
          @title << "for #{@packages.first.name}"
          @updateid = @packages.first.name
        elsif @packages.size < 1
          # do nothing, it is may be just a message
        else
          # figure out what the multiple packages are
          if @packages.grep(/kde/).size > 1
            # assume it is a KDE update
            @title << "for KDE"
            # KDE 3 or KDE4
            @updateid = "KDE3" if @packages.grep(/kde(.+)3$/).size > 1
            @updateid = "KDE4" if @packages.grep(/kde(.+)4$/).size > 1
          elsif @packages.grep(/kernel/).size > 1
            @title << "for the Linux kernel"
            @updateid = 'kernel'
          end
        end
        # now figure out and fill references
        # second format is a weird non correct format some developers use
        # Novell bugzilla
        bugzillas = description.scan(/BNC\:\s?(\d+)|bnc\s?#(\d+)|b\.n\.c (\d+)|n#(\d+)/i)
        bugzillas.each do |bnc|
          ref = Reference.new
          ref.href << "/#{bnc}"
          ref.referenceid = bnc
          ref.title = "bug number #{bnc}"
          @references << ref
        end
        # Redhat bugzilla
        rhbz = description.scan(/rh\s?#(\d+)|rhbz\s?#(\d+)/)
        rhbz.each do |rhbz|
          ref = Reference.new
          ref.href = "http://bugzilla.redhat.com/#{rhbz}"
          ref.referenceid = rhbz
          ref.title = "Redhat's bug number #{rhbz}"
          @references << ref
        end
        # gnome
        bgo = description.scan(/bgo\s?#(\d+)|BGO\s?#(\d+)/)
        bgo.each do |bgo|
          ref = Reference.new
          ref.href << "http://bugzilla.gnome.org/#{bgo}"
          ref.referenceid = bgo
          ref.title = "Gnome bug number #{bgo}"
          @references << ref
        end

        # KDE
        bko = description.scan(/kde\s?#(\d+)|KDE\s?#(\d+)/)
        bko.each do |bko|
          ref = Reference.new
          ref.href << "http://bugs.kde.org/#{bko}"
          ref.referenceid = bko
          ref.title = "KDE bug number #{bko}"
          @references << ref
        end
        # CVE security
        cves = description.scan(/CVE-([\d-]+)/)
        cves.each do |cve|
          ref = Reference.new
          ref.href = "http://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-#{cve}"
          ref.referenceid = "#{cve}"
          ref.type = 'cve'
          ref.title = "CVE number #{cve}"
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
          b.id(@updateid)
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

      attr_reader :log
      
      def initialize(log, config)
        @log = log
        @dir = config.dir
        @basedir = config.updatesbasedir

        # update files
        @updates = Set.new
      end

      def empty?
        return @updates.empty?
      end
      
      def add_updates
        Dir["#{@dir}/**/update-*.xml"].each do |updatefile|
          log.info("Adding update #{updatefile}")
          @updates << updatefile
        end
        # end of directory iteration
      end

      # generates a patch from a list of package names
      # it compares the last version of those package names
      # with their previous ones
      #
      # outputdir is the directory where to save the patch to.
      def generate_update(packages, outputdir)
        
        # make a hash name -> array of packages
        log.info "generating update..."
        pkgs = Hash.new
        [ Dir["#{@dir}/**/*.rpm"], @basedir.nil? ? [] : Dir["#{@basedir}/**/*.rpm"]].flatten.each do |rpmfile|
          next if rpmfile =~ /\.delta\.rpm$/
          # in case we are working with a big base directory
          # it would be expensive to read all package headers
          # so exclude packages with different name
          # it has to match at least one
          matched = false
          packages.each do |pkg|
            result=pkg.gsub(/\+/, "\\\\+")
            matched = true if rpmfile =~ /#{result}/
          end
          # dont read the package header if this rpm
          # is not useful
          next if not matched
          
          rpm = PackageId.new(rpmfile)
          # if the rpm we found is not in the list of packages
          # we are doing the update for, we just skip it
          next if not packages.include?(rpm.name)
          
          pkgs[rpm.name] = Array.new if not pkgs.has_key?(rpm.name)
          pkgs[rpm.name] << rpm
        end

        # do our package hash include every package?
        packages.each do |pkg|
          if not pkgs.has_key?(pkg)
            log.info "the package '#{pkg}' is not available in the repository."
          end
        end

        update = Update.new
        
        packages.each do |pkgname|
          pkglist = pkgs[pkgname]
          log.info "#{pkglist.size} versions for '#{pkgname}'"
          # sort them by version
          pkglist.sort! { |a,b| a.version <=> b.version }
          pkglist.reverse!
          # now that the list is sorted, the new rpm is the first

          # if there is only one package then we don't need changelog
          if pkglist.size > 1
            first = pkglist.shift
            second = pkglist.shift
            # go down old version until there is some different package
            diff = []
            while diff.empty?
              diff = first.changelog[0, first.changelog.size - second.changelog.size]
              break if pkglist.empty?
              second = pkglist.shift
            end
            
            log.info "Found change #{first.ident} and #{second.ident}."
            
            log.info "'#{pkgname}' has #{diff.size} entries (#{first.changelog.size}/#{second.changelog.size})"
            update.packages << first
            diff.each do |entry|
              update.description << entry.text << "\n"          
            end
          else
            # jump to next pkgname
            next
          end
          
        end
        # before writing the update, figure out more
        # information
        update.smart_fill_blank_fields
        filename = ""

        # increase version until version is available
        while ( File.exists?(filename = File.join(outputdir, update.suggested_filename + ".xml") ))
          update.version += 1
        end
        log.info "Saving update part to '#{filename}'."
        
        f = File.open(filename, 'w')
        update.write(f)
        f.close
      end
      
      # write a update out
      def write(file)
        builder = Builder::XmlMarkup.new(:target=>file, :indent=>2)
        builder.instruct!
        xml = builder.updates do |b|
          @updates.each do |update|
            file << File.open(update).read
            #update.append_to_builder(b)
          end
        end #done builder
      end
      
    end


  end
end
