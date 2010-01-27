require 'Item'
require 'SeqMiner'

module Family
	include Item
	
	class Set < Set
		attr_reader :config
		
		def initialize(options = {:config => config})
			super()
			
			if options[:config]
				@config = options[:config]
			else
				@config = SeqMiner::Config.new
			end
			
			file = config.dir_config + "family.txt"
			fo = File.open(file)
			fo.each_line do |line|
				line.chomp!
				t, o, fn = line.split("\t")
				family = Family.new(t + "." + o)
				family.name = fn
				self << family
			end
			fo.close
		end
		
		def each_family
			items.each_value do |val|
				yield val
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
		attr_accessor :name
		
		def initialize(id)
			super
		end
		
		def debug
			warn "+ Family +"
			warn "* id: " + id
			warn "* name: " + name
		end
	end
end