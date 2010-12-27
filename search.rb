# SeqMiner is a tool for mining sequence information. It aims to
# help detect sequences belonging to specific protein families.
#
# Author::    Diego Diez  (mailto:diez@kuicr.kyoto-u.ac.jp)
# Copyright:: Copyright (c) 2010
# License::   Distributes under the same terms as Ruby

require 'config'
require 'ortholog'
require 'taxon'
require 'tools'
require 'result'
require 'common'

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
		include Common

		def initialize(ps = nil, options = {:empty => false, :config => nil})
			super()
			
			if ! options[:config]
				@config = Config::General.new
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
			each_value do |value|
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
					hr = Tools::Hmmer.new('hmmsearch', options = {:config => config})
					hr.infile = config.dir_sequence + search.taxon.name + (search.type.name + ".fa")
					hr.model = config.dir_model + "hmm" + search.ortholog.hmm
					hr.outfile = config.dir_result + "genome/search" + search.ortholog.name + (search.id + ".log")
					hr.debug
					res = hr.execute
					_check_result(res)
				when 'clade'
					warn "* search id: " + search.id
					st = Tools::Blast.new('tblastn', options = {:config => config})
					st.pssm_file = config.dir_model + "pssm" + (search.ortholog.name + ".pssm")
					#st.seed_file = config.dir_model + "pssm" + (search.ortholog.name + ".seed")
					st.db = config.dir_sequence + search.taxon.name + (search.type.name)
					st.outfile = config.dir_result + "isolate/search" + search.ortholog.name + (search.id + ".txt")
					st.debug
					res = st.execute
					_check_result(res)
				end
			end
		end

		# this method parses results from a search.
		def parse
			rs = Result::Set.new(options = {:config => config})
			
			transferred = 0
			pb = ProgressBar.new("Search results", 100)
			each_value do |search|
				case search.taxon.type
				when 'spp'
					file = config.dir_result + "genome/search" + search.ortholog.name + (search.id + ".txt")
					
					rp = Result::HmmerParser.new(options = {:tool => 'hmmsearch', :config => config})
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
					
					rp = Result::BlastParser.new(options = {:tool => 'psitblastn', :config => config})
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
				transferred += 1
				percent_finished = 100 * (transferred.to_f / length.to_f)
				pb.set(percent_finished)
			end
			pb.finish
			
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
