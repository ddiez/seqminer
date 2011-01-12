# SeqMiner is a tool for mining sequence information. It aims to
# help detect sequences belonging to specific protein families.
#
# Author::    Diego Diez  (mailto:diez@kuicr.kyoto-u.ac.jp)
# Copyright:: Copyright (c) 2010
# License::   Distributes under the same terms as Ruby

require 'item'
require 'config'

module Family
	include Item
	
	class Set < Set
		attr_reader :config
		
		def initialize(options = {:config => config})
			super()
			
			if options[:config]
				@config = options[:config]
			else
				@config = Config::General.new
			end
			
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
			warn "+ FamilySet +"
			warn "* length: " + length.to_s
			each_family do |family|
				family.debug
			end
		end
	end
	
	class Family < Item
		attr_accessor :name, :taxon, :ortholog
		
		def initialize(id)
			super
		end
		
		def debug
			warn "+ Family +"
			warn "* id: " + id
			warn "* taxon: " + taxon
			warn "* ortholog: " + ortholog
			warn "* name: " + name
		end
	end
end
