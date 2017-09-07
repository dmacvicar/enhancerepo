# Encoding: utf-8

require 'enhance_repo/rpm_md/pattern_writer'

module EnhanceRepo
  class Pattern
    # include serialization
    include RpmMd::PatternWriter

    attr_accessor :name
    attr_accessor :version
    attr_accessor :release
    attr_accessor :architecture
    attr_accessor :summary
    attr_accessor :description
    attr_accessor :icon
    attr_accessor :order
    attr_accessor :visible
    attr_accessor :category
    attr_accessor :supplements
    attr_accessor :conflicts
    attr_accessor :provides
    attr_accessor :requires
    attr_accessor :recommends
    attr_accessor :suggests
    attr_accessor :extends
    attr_accessor :includes

    def initialize
      @name        = ''
      @version     = ''
      @release     = ''
      @architecture = 'noarch'
      @summary     = {}
      @description = {}
      @icon        = nil
      @order       = 0
      @visible     = true
      @category    = {}
      @supplements = {}
      @conflicts   = {}
      @provides    = {}
      @requires    = {}
      @recommends  = {}
      @suggests    = {}
      @extends     = {}
      @includes    = {}
    end
  end
end
