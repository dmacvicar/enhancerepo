
require 'rubygems'
require 'builder'
require 'rexml/document'
require 'yaml'

include REXML

class UpdateInfo

  def initialize(dir)
    @dir = dir
    @nodes = []
  end

  def empty?
    return @nodes.empty?
  end
  
  def add_updates
    Dir["#{@dir}/**/*.update"].each do |updatefile|
      node = YAML.load(File.new(updatefile).read)
      STDERR.puts("Adding update #{updatefile}")
      @nodes << node
    end
    # end of directory iteration
  end

  # write a update out
  def write(file)
    builder = Builder::XmlMarkup.new(:target=>file, :indent=>2)
    builder.instruct!
    xml = builder.updates do |b|
      @nodes.each do |updates|
        updates.each do |k, v|
          # k is update here
          # v are the attributes
          # default patch issuer
          puts v.inspect
          from = "#{ENV['USER']}@#{ENV['HOST']}"
          type = "optional"
          version = "1"
          from = v['from'] ? v['from'] : from
          type = v['type'] if not v['type'].nil?
          version = v['version'] if not v['version'].nil?
          
          b.update('status' => 'stable', 'from' => from, 'version' => version, 'type' => type) do |b|
            b.title(v['summary'])
            b.id(v['id'] ? v['id'] : "no-id")
            b.issued(v['issued'] ? v['issued'] : Time.now.to_i.to_s )
            b.release(v['release'])
            b.description(v['description'])
            b.references do |b|
              v['references'].each do |k,v|
                b.reference(v)
              end   
            end
          end
        end
      end
    end #done builder

  end
end

