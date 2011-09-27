require 'item'
require 'config'
require 'ortholog'
require 'taxon'
require 'tools'
require 'common'

require 'progressbar'

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
				case scan.taxon.type
				when 'spp'
					dir = config.dir_result + "genome/fasta" + scan.ortholog.name
					outdir = config.dir_result + "genome/scan" + scan.ortholog.name
				when 'clade'
					dir = config.dir_result + "isolate/fasta" + scan.ortholog.name
					outdir = config.dir_result + "isolate/scan" + scan.ortholog.name
				end
				file = dir + (scan.taxon.name + "-" + scan.ortholog.name + "_protein.fa")
				if file.exist?
					warn "* search domains in: " + file
					ts = Tools::Hmmer.new("hmmscan", options = {:config => config})
					ts.model = config.dir_pfam_current + "Pfam-A.hmm"
					ts.infile = file
					ts.outfile = outdir + (scan.taxon.name + "-" + scan.ortholog.name + "_protein.log")
					ts.table_file = outdir + (scan.taxon.name + "-" + scan.ortholog.name + "_protein.txt")
					ts.debug
					res = ts.execute
					_check_result(res)
				end
			end
		end
		
		def parse
			rs = Result::Set.new(options = {:config => config})
			
			transferred = 0
			pb = ProgressBar.new("Scan results", 100)
			each_value do |scan|
				case scan.taxon.type
				when 'spp'
					dir = config.dir_result + "genome/scan" + scan.ortholog.name
					outdir = config.dir_result + "genome/domain" + scan.ortholog.name
				when 'clade'
					dir = config.dir_result + "isolate/scan" + scan.ortholog.name
					outdir = config.dir_result + "isolate/domain" + scan.ortholog.name
				end
				file = dir + (scan.taxon.name + "-" + scan.ortholog.name + "_protein.txt")
				if file.exist?
					rp = Result::HmmerParser.new(options = {:tool => 'hmmscan', :config => config})
					rp.file = file
					rp.result_id = scan.taxon.name + "-" + scan.ortholog.name
					rp.type = "protein"
					rp.config = config
					r = rp.parse
					r.taxon = scan.taxon
					r.ortholog = scan.ortholog
					r.type = "protein"
					rs << r
				end
				transferred += 1
				percent_finished = 100 * (transferred.to_f / length.to_f)
				pb.set(percent_finished.to_i)
			end
			pb.finish
			rs
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