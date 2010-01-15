require 'SeqMiner'
require 'Item'

module Taxon
	include Item
	
	class Set < Set
		attr_reader :config
		def initialize(options = { :empty => false, :config => nil })
			super()
			
			if ! options[:config]
				@config = SeqMiner::Config.new
			else
				@config = options[:config]
			end

			if ! options[:empty]
				tf = config.file_taxon
				file = File.open(tf)
				file.each do |line|
					next if line.match(/^#/)
					line = line.chomp
					next if line == ""
					id, name1, name2, strain, type, source = line.split("\t")
					#warn "* Taxon: " + id.to_s
	
					taxon = Taxon.new(id, name1, name2, strain, type, source)
					add(taxon)
				end
				file.close
			end
		end
		
		def get_taxon_by_name(name)
			each_value do |item|
				#warn "* searching " + name + " on " + item.name
				return item if item.name == name
			end
			return nil
		end
		
		def filter_by_name(filter)
			items.delete_if {|name, taxon| ! taxon.name.match(/#{filter}/) }
		end
		
		def filter_by_type(filter)
			items.delete_if {|name, taxon| ! taxon.type.match(/#{filter}/) }
		end

		def filter_by_source(filter)
			items.delete_if {|name, taxon| ! taxon.source.match(/#{filter}/) }
		end
		
		def debug
			warn "+ Taxon Set +"
			warn "* length: " + length.to_s
			items.each_value do |taxon|
				taxon.debug
			end
			warn ""
		end
	end

	class Taxon < Item
		attr_accessor :name, :strain, :binomial, :type, :source, :kegg_name, :short_name

		def initialize (id, name1, name2, strain, type, source)
			super(id)
			name = name1 + "." + name2
			name = name + "_" + strain if strain != ""
			@name = name
			@strain = strain
			@type = type
			@source = source
			@binomial = name1 + "." + name2
			@short_name = name1.match(/^(.)/)[0].upcase + name2
			@kegg_name = name1.match(/^(.)/)[0] + name2.match(/^(..)/)[0] + (strain == "" ? "" : "_" + strain)
		end
		

		def debug
			warn "+ Taxon +"
			warn "* taxon_id: " + @id
			warn "* organism: " + @name
			warn "* type: " + @type
			warn "* source: " + @source
		end
	end
end
