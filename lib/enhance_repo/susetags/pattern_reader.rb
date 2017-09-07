# Encoding: utf-8

require 'enhance_repo/pattern'

module EnhanceRepo
  module Susetags
    module PatternReader
      def self.read_patterns_from_tags(io)
        pats = []
        pattern = nil

        in_des = false
        in_req = false
        in_rec = false
        in_sug = false
        in_sup = false
        in_con = false
        in_prv = false
        in_ext = false
        in_inc = false
        kind = "package"
        cur_lang = ""
        description = ""
        requires = []
        recommends = []
        suggests = []
        io.each_line do |line|
          if line.start_with?("=Pat:")
            # save the previous one
            pats << pattern unless pattern.nil?
            # a new patern starts here
            pattern = Pattern.new
            v = line.split(/:\s*/, 2)
            a = v[1].chomp.split(/\s/, 4)
            pattern.name = a[0] if a.length >= 1
            pattern.version = a[1] if a.length >= 2
            pattern.release = a[2] if a.length >= 3
            pattern.architecture = a[3] if a.length >= 4
          elsif line.start_with?("=Cat")
            v = line.match(/=Cat\.?(\w*):\s*(.*)$/)
            pattern.category[(v[1]).to_s] = v[2].chomp
          elsif line.start_with?("=Sum")
            v = line.match(/=Sum\.?(\w*):\s*(.*)$/)
            pattern.summary[(v[1]).to_s] = v[2].chomp
          elsif line.start_with?("=Ico:")
            v = line.split(/:\s*/, 2)
            pattern.icon = v[1].chomp
          elsif line.start_with?("=Ord:")
            v = line.split(/:\s*/, 2)
            pattern.order = v[1].chomp.to_i
          elsif line.start_with?("=Vis:")
            pattern.visible = if line.include?("true")
              true
                              else
              false
                              end
          elsif line.start_with?("+Des")
            in_des = true
            cur_lang = line.match(/\+Des\.?(\w*):/)[1]
          elsif line.start_with?("-Des")
            in_des = false
            pattern.description[cur_lang] = description.lstrip
            cur_lang = ""
            description = ""
          elsif line.start_with?("+Req:")
            in_req = true
            kind = "pattern"
          elsif line.start_with?("-Req:")
            in_req = false
            kind = "package"
          elsif line.start_with?("+Sup:")
            in_sup = true
            kind = "pattern"
          elsif line.start_with?("-Sup:")
            in_sup = false
            kind = "package"
          elsif line.start_with?("+Con:")
            in_con = true
            kind = "pattern"
          elsif line.start_with?("-Con:")
            in_con = false
            kind = "package"
          elsif line.start_with?("+Prv:")
            in_prv = true
            kind = "pattern"
          elsif line.start_with?("-Prv:")
            in_prv = false
            kind = "package"
          elsif line.start_with?("+Prc:")
            in_rec = true
            kind = "package"
          elsif line.start_with?("-Prc:")
            in_rec = false
          elsif line.start_with?("+Prq:")
            in_req = true
            kind = "package"
          elsif line.start_with?("-Prq:")
            in_req = false
          elsif line.start_with?("+Psg:")
            in_sug = true
            kind = "package"
          elsif line.start_with?("-Psg:")
            in_sug = false
          elsif line.start_with?("+Ext:")
            in_ext = true
            kind = "pattern"
          elsif line.start_with?("-Ext:")
            in_ext = false
            kind = "package"
          elsif line.start_with?("+Inc:")
            in_req = true
            kind = "pattern"
          elsif line.start_with?("-Inc:")
            in_inc = false
            kind = "package"
          elsif in_des
            description << line
          elsif in_con
            pattern.conflicts[line.chomp] = kind
          elsif in_sup
            pattern.supplements[line.chomp] = kind
          elsif in_prv
            pattern.provides[line.chomp] = kind
          elsif in_req
            pattern.requires[line.chomp] = kind
          elsif in_rec
            pattern.recommends[line.chomp] = kind
          elsif in_sug
            pattern.suggests[line.chomp] = kind
          elsif in_ext
            pattern.extends[line.chomp] = kind
          elsif in_inc
            pattern.includes[line.chomp] = kind
          end
        end
        # the last pattern
        pats << pattern unless pattern.nil?
        pats
      end
    end
  end
end