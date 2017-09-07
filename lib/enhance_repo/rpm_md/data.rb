# Encoding: utf-8

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
  module RpmMd
    # represents a metadata unit
    class Data
      include Logger

      # initialize the extra data with a name
      # or use the class name as default
      def initialize(name)
        @name = name
      end

      def name
        defined?(@name) ? @name : self.class.to_s.split("::").last.downcase
      end

      def metadata_filename
        "repodata/#{name}.xml#{should_compress? ? '.gz' : ''}"
      end

      # wether the metadata should be compressed
      def should_compress?
        true
      end
    end
  end
end
