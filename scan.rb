require 'config'
require 'ortholog'
require 'taxon'
require 'tools'


module Scan
	include Item

	class Set < Set
		attr_accessor :parameters
		attr_reader :config
		include Common
		
		def initialize(ps, options = {:empty => false, :config => nil})
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
		end
		
		def populate
			parameters.taxon.each_value do |taxon|
				parameters.ortholog.each_value do |ortholog|
!						scan = Scan.new(taxon, ortholog)
						add(scan)
				end
			end
		end
		
		def scan
			warn "+ Running scan +"
			each_value do |scan|
				scan.scan
			end
		end
	end
	
	class Scan < Item
		attr_accessor :taxon, :ortholog, :config
		
		# TODO: fix config method.
		def initialize (taxon, ortholog)
			@taxon = taxon
			@ortholog = ortholog
			super(taxon.name + "-" + ortholog.name)
		end
		
		def scan
			case taxon.type
			when 'spp'
				dir = config.dir_result + "genome/fasta" + o.name
				outdir = config.dir_result + "genome/scan" + o.name
			when 'clade'
				dir = config.dir_result + "isolate/fasta" + o.name
				outdir = config.dir_result + "isolate/scan" + o.name
			end
			file = dir + (t.name + "-" + o.name + "_protein.fa")
			if file.exist?
				warn "* search domains in: " + file
				ts = Tools::Hmmer.new("hmmscan")
				ts.model = config.dir_pfam_current + "Pfam-A.hmm"
				ts.infile = file
				ts.outfile = outdir + (t.name + "-" + o.name + "_protein.log")
				ts.table_file = outdir + (t.name + "-" + o.name + "_protein.txt")
				ts.debug
#				res = ts.execute
#				_check_result(res)
			end
		end
		
		def parse
		end
		
		def debug
			warn "+ Scan +"
			warn "* id: " + id
			warn "* taxon: " + taxon.name
			warn "* ortholog: " + ortholog.name
			warn "* type: " + type.name
			warn "* hmm: " + ortholog.hmm
		end
	end
end