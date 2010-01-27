require 'SeqMiner'
require 'Ortholog'
require 'Taxon'
require 'Tools'
require 'Result'
require 'term/ansicolor'

module Search
	include Item
	
	class TypeSet < Set
		def initialize(options = {:empty => false})
			super()
			@types = ["cds", "6frame", "protein"]
			if ! options[:empty]
				@types.each do |type|
					add(Type.new(length + 1, type))
				end
			end
		end
		
		def debug
			warn "+ Parameter Set +"
			super
		end
	end
	
	class Type < Item
		def initialize(id, type)
			super(id)
			@valid_types = ["cds", "6frame", "protein"]
			@type = validate_type(type)
		end
		
		def name=(val)
			@type = validate_type(val)
			if @type.nil?
				raise "Invalid value for 'type' #{val}."
				exit
			end
		end
		
		def name
			@type
		end
		
		def validate_type(val)
			if @valid_types.include?(val)
				val
			else
				nil
			end
		end
		
		def debug
			warn "+ Parameter Type +"
			warn "* type: " + name
		end
	end

	class Parameter
		attr_accessor :taxon, :ortholog, :type

		def initialize(*args)
			if args.length == 0
				@taxon = Taxon::Set.new
				@ortholog = Ortholog::Set.new
				@type = TypeSet.new
			elsif args.length == 3
				@taxon = args[0]
				@ortholog = args[1]
				@type = args[2]
			end
		end

		def debug
			warn "+ Parameter +"
			warn "* taxon: " + taxon.length.to_s
			warn "* ortholog: " + ortholog.length.to_s
			warn "* type: " + type.length.to_s
			warn ""
		end
	end
	
	class Set < Set
		attr_accessor :parameters
		attr_reader :config
		include Term::ANSIColor
		def initialize(ps = nil, options = {:empty => false, :config => nil})
			super()
			
			if ! options[:config]
				@config = SeqMiner::Config.new
			else
				@config = options[:config]
			end

			if ! options[:empty]
				if ! ps.nil?
					@parameters = ps
					populate
				else
					raise "ERROR: need a valid ParameterSet object"
					exit
				end
			end
			
			# TODO: should parameters be empty if empty = true?
			#@parameters = Parameters.new
			
#			if ! empty
#				add(ts, os, ps)
#			end
		end
		
		def each_search
			items.each_value do |value|
				yield value
			end
		end
		
		def populate
			parameters.taxon.each_value do |taxon|
				parameters.ortholog.each_value do |ortholog|
					parameters.type.each_value do |type|
						# This two lines are a hack until I find a better solution.
						next if taxon.type == "spp" and type.name == "cds"
						next if taxon.type == "clade" and type.name != "cds"
						# Here we go.
						search = Search.new(taxon, ortholog, type)
						add(search)
					end
				end
			end
		end
		
		def search
			warn "+ Running search +"
			each_value do |search|
				case search.taxon.type
				when 'spp'
					warn "* search id: " + search.id
					hr = Tools::Hmmer.new(options = {:config => config})
					hr.tool = "hmmsearch"
					hr.infile = config.dir_sequence + search.taxon.name + (search.type.name + ".fa")
					hr.model = config.dir_model + "hmm" + search.ortholog.hmm
					hr.outfile = config.dir_result + "genome/search" + search.ortholog.name + (search.id + ".log")
					hr.debug
					res = hr.execute
				when 'clade'
					warn "* search id: " + search.id
					st = Tools::Blast.new(options = {:config => config})
					st.tool = 'tblastn'
					st.pssm_file = config.dir_model + "pssm" + (search.ortholog.name + ".chk")
					#st.seed_file = config.dir_model + "pssm" + (search.ortholog.name + ".seed")
					st.db = config.dir_sequence + search.taxon.name + (search.type.name)
					st.outfile = config.dir_result + "isolate/search" + search.ortholog.name + (search.id + ".txt")
					st.debug
					res = st.execute
				end
				
				if res
                    $stderr.puts green, bold, "[DONE]", reset
                else
                    $stderr.puts red, bold, "[FAIL]", reset
                end
				warn ""
			end
		end

		# this method parses results from a search.
		def parse
			rs = Result::Set.new
			each_value do |search|
				case search.taxon.type
				when 'spp'
					file = config.dir_result + "genome/search" + search.ortholog.name + (search.id + ".txt")
					
					rp = Result::HmmerParser.new
					rp.file = file
					rp.result_id = search.id
					rp.type = search.type.name
					rp.config = config # this makes sense in this case since HmmerParse is not using Config, but passing it to the Result.
					r = rp.parse
					r.taxon = search.taxon
					r.ortholog = search.ortholog
					r.type = search.type
					rs << r
				when 'clade'
					file = config.dir_result + "isolate/search" + search.ortholog.name + (search.id + ".txt")
					
					rp = Result::BlastParser.new
					rp.file = file
					rp.result_id = search.id
					rp.type = search.type.name
					rp.config = config
					r = rp.parse
					r.taxon = search.taxon
					r.ortholog = search.ortholog
					r.type = search.type
					rs << r
				end
			end
			rs
		end
		
		def debug
			warn "+ SEARCH SET +"
			super
			warn ""
		end
	end

	class Search < Item
		attr_accessor :taxon, :ortholog, :type

		def initialize (taxon, ortholog, type)
			@taxon = taxon
			@ortholog = ortholog
			@type = type
			super(taxon.name + "-" + ortholog.name + "-" + type.name)
		end

		def debug
			warn "+ Search +"
			warn "* id: " + id
			warn "* taxon: " + taxon.name
			warn "* ortholog: " + ortholog.name
			warn "* type: " + type.name
			warn "* hmm: " + ortholog.hmm
		end
	end
end
