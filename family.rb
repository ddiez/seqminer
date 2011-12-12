# SeqMiner is a tool for mining sequence information. It aims to
# help detect sequences belonging to specific protein families.
#
# Author::    Diego Diez  (mailto:diez@kuicr.kyoto-u.ac.jp)
# Copyright:: Copyright (c) 2010
# License::   Distributes under the same terms as Ruby

require 'item'
require 'config'
require 'common'

module Family
	include Item
	
	class Set < Set
		include Common
		
		attr_reader :config, :file_log
		
		def initialize(options = {:config => config})
			super()
			
			if options[:config]
				@config = options[:config]
			else
				@config = Config::General.new
			end
			@file_log = config.file_log
			
			file = config.dir_config + "family.txt"
			fo = File.open(file)
			fo.each_line do |line|
				next if line.match(/^#/)
				line.chomp!
				t, o, fn = line.split("\t")
				family = Family.new(t + "-" + o)
				family.name = fn
				family.taxon = t
				family.ortholog = o
				family.file_log = file_log
				self << family
			end
			fo.close
		end
		
		def each_family
			each_value do |val|
				yield val
			end
		end
		
		def filter_by_taxon(filter)
			dt = []
			each_family do |family|
				m = false
				filter.each do |f|
					if family.taxon.match(/#{f}/)
						m = true
						break
					end
				end
				dt << family if ! m
			end
			dt.each do |family|
				delete(family)
			end
		end
		
		def filter_by_ortholog(filter)
			dt = []
			each_family do |family|
				m = false
				filter.each do |f|
					if family.ortholog.match(/#{f}/)
						m = true
						break
					end
				end
				dt << family if ! m
			end
			dt.each do |family|
				delete(family)
			end
		end
		
		def filter_by_name(filter)
			dt = []
			each_family do |family|
				m = false
				filter.each do |f|
					if family.name.match(/#{f}/)
						m = true
						break
					end
				end
				dt << family if ! m
			end
			dt.each do |family|
				delete(family)
			end
		end
		
		def debug
			info "+ FamilySet +"
			info "* length: " + length.to_s
			each_family do |family|
				family.debug
			end
		end
	end
	
	class Family < Item
		include Common
		attr_accessor :name, :taxon, :ortholog, :file_log
		
		def initialize(id)
			super
		end
		
		def file_log=(file)
			@file_log = file
		end

		def debug
			info "+ Family +"
			info "* id: " + id
			info "* taxon: " + taxon
			info "* ortholog: " + ortholog
			info "* name: " + name
		end
	end
end
