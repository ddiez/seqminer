require 'seqminer'
require 'item'

module Ortholog
	include Item

	class Set < Set
		attr_reader :config
		def initialize(options = {:empty => false, :config => nil})
			super()

			if ! options[:config]
				@config = SeqMiner::Config.new
			else
				@config = options[:config]
			end
			
			if ! options[:empty]
				of = config.file_ortholog
				file = File.open(of)
				file.each do |line|
					line = line.chomp
					next if line == ""
					next if line =~ /^#/
					name, hmm = line.split("\t")
					#warn "* Ortholog: " + name
	
					ortholog = Ortholog.new(name, hmm)
					self.add(ortholog)
				end
				file.close
			end
		end
		
		def each_ortholog
			items.each_value do |value|
				yield value
			end
		end
		
		def get_ortholog_by_name(name)
			each_ortholog do |o|
				return o if o.name == name
			end
			return nil
		end
		
		def filter_by_name(filter)
			items.delete_if { |name, ortholog| ! name.match(/#{filter}/) }
		end

		def debug
			warn "+ Ortholog Set+"
			warn "* length: " + length.to_s
			each_value do |ortholog|
				ortholog.debug
			end
			warn ""
		end
	end

	class Ortholog < Item
		attr_accessor :hmm, :name

		def initialize (name, hmm)
			super(name.to_s + "." + hmm.to_s)
			@name = name
			@hmm = hmm
		end

		def debug
			warn "+ Ortholog +"
			warn "* id: " + id
			warn "* name: " + name
			warn "* hmm: " + hmm
		end
	end
end
