#--
# 
# enhancerepo is a rpm-md repository metadata tool.
# Copyright (C) 2008, 2009 Novell Inc.
# Author: Duncan Mac-Vicar P. <dmacvicar@suse.de>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
# MA  02110-1301, USA.  A copy of the GNU General Public License is
# also available at http://www.gnu.org/copyleft/gpl.html.
#
#++
#

module EnhanceRepo

  def self.enable_logger
    # support both log4r and ruby logger
    begin
      require 'log4r'
      include Log4r
      @logger = Log4r::Logger.new 'enhancerepo'
      console_format = Log4r::PatternFormatter.new(:pattern => "%l:\t %m")
      @logger.add Log4r::StdoutOutputter.new('console', :formatter=>console_format)
    rescue LoadError
      require 'logger'
      @logger = ::Logger.new(STDERR)
    end
    EnhanceRepo.logger.level = using_log4r? ? Log4r::INFO : ::Logger::INFO
  end

  def self.using_log4r?
    (! (Object.const_get(:Log4r) rescue nil).nil?)
  end
  
  def self.enable_debug
    EnhanceRepo.logger.level = using_log4r? ? Log4r::DEBUG : ::Logger::DEBUG
  end
  
  def self.logger
    @logger
  end

  def self.logger=(logger)
      @logger = logger
  end
  
  # provide easy access to classes to the
  # global logger
  module Logger
    def log
      EnhanceRepo.logger
    end
  end
  
end
