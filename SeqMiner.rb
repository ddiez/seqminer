require 'Pathname'

#require 'FileUtils'
require 'Taxon'
require 'Ortholog'
require 'Search'
require 'Result'
require 'Download'

module SeqMiner
	class Config
		# Directories.
		attr_accessor :dir_home
		attr_reader :dir_source, :dir_sequence, :dir_model, :dir_pfam, :dir_config, :dir_result_base, :dir_result
		# Tools directories.
		attr_accessor :dir_hmmer, :dir_blast
		# Files.
		attr_reader :file_taxon, :file_ortholog

		def initialize
			# Basedir.
			@dir_home = Pathname.new("/Volumes/Biodev/projects/vardb/sm")
			update
		end
		
		def update
			# Configuration.
			@dir_config = dir_home + "etc"
			@file_taxon = dir_config + "taxon.txt"
			@file_ortholog = dir_config + "ortholog.txt"
			
			# Databases.
			@dir_source = dir_home + "source"
			@dir_sequence = dir_home + "sequence"
			@dir_model = dir_home + "model"
			@dir_pfam = dir_home + "pfam"
			
			# Results.
			@dir_result_base = dir_home + "result"
			@dir_result = dir_result_base + "last"
			
			# Tools.
			@dir_hmmer = Pathname.new("/Users/diez/local/hmmer3/bin/")
			@dir_blast = Pathname.new("/Users/diez/local/blast/bin/")
		end
		
		def basedir=(dir)
			@dir_home = Pathname.new(dir).expand_path
			update
		end
		
		def basedir
			@dir_home
		end
		
		def dir_result=(dir)
			@dir_result = dir_result_base + dir
		end

		def debug
			puts "+ Config +"
			puts "* dir_home: " + dir_home
			puts "* dir_result: " + dir_result
		end
	end
	
	class Install
		attr_reader :project, :config, :taxon, :ortholog

		def initialize(options = {:config => nil})
			
			if ! options[:config]
				@config = Config.new
			else
				@config = options[:config]
			end
			
			@taxon = Taxon::Set.new(options = {:config => config})
			@ortholog = Ortholog::Set.new(options = {:config => config})
		end
		
		def install
			create_dir_structure
			update_databases
		end
		
		def create_dir_structure
			create_base_dir
			config.dir_source.mkpath
			config.dir_model.mkpath
			config.dir_sequence.mkpath
			config.dir_pfam.mkpath
			config.dir_result_base.mkpath
			config.dir_config.mkpath
		end
		
		def create_base_dir
			if config.dir_home.exist?
				warn "ERROR: target directory already exists. Incompatible with instalation."
				exit
			else
				warn "* creating dir_home: " + config.dir_home
				config.dir_home.mkpath
			end
		end
		
		def update_databases
			update_pfam
			update_sequences
		end
		
		def update_pfam
			d = Download::Pfam.new(options = {:config => config})
			d.update
		end
		
		def update_sequences
			d = Download::Set.new(taxon, options = {:config => config})
			d.download
		end
	end
	
	class Pipeline
		attr_accessor :taxon, :ortholog, :search, :result
		attr_reader :config
		
		def initialize(options = {:config => nil})

			if ! options[:config]
				@config = Config.new
			else
				@config = options[:config]
			end

			config.debug

			@taxon = Taxon::Set.new(options = {:config => config})
			@ortholog = Ortholog::Set.new(options = {:config => config})
			@type = Search::TypeSet.new(options = {:config => config})
			build_search
			
			@dir_initialized = false
		end

		def dir_initialized?
			@dir_initialized
		end
		
		def dir_initialize
			dir_level1 = ['genome']
			dir_level2 = ['search', 'sequences', 'fasta']
			
			if ! config.dir_result.exist?
				warn "+ CREATE RESULT DIR STRUCTURE +"
				#warn "* " + dir_result
				#dir_result.mkpath
				dir_level1.each do |level1|
					dir_level2.each do |level2|
						ortholog.items.each_value do |ortholog|
							dir = config.dir_result + level1 + level2 + ortholog.name
							warn "* " + dir
							dir.mkpath
						end
					end
				end
			end
		end

		def run_all
			run_search
			get_results
			export_nelson
			export_fasta
		end
		
		def build_search
			ps = Search::Parameter.new(@taxon, @ortholog, @type)
			@search = Search::Set.new(ps, options = {:config => config})
		end
		
		# Initializes the result directory structure if needed, then performs the searches.
		def run_search
			dir_initialize if ! dir_initialized?
			@search.search
		end
		
		# Parses the HMMER files, performs auto_merge and obtains the results (given an Evalue thereshold).
		def get_results(eval = 0.001)
			@result = @search.parse
			@result = result.auto_merge
			result.filter_by_eval(eval)
		end

		def export_nelson
			if result.nil?
				get_results
			end
			result.export_nelson
		end

		# Pipeline-wise export_fasta.
		def export_fasta
			if result.nil?
				get_results
			end
			result.export_fasta
		end
		
		# Pipeline-wise report.
		def report(completeness = 1)
			if result.nil?
				get_results
			end
			result.report(cut = completeness)
		end
		
		# Pipeline-wise summary report.
		def report_summary
			if result.nil?
				get_results
			end
			result.report_summary
		end
		
		# This function automatically generate protein alignments by concatenating the FASTA files for protein
		# for sequences in the same gene family. Then runs Clustalw-mpi on the concatenated FASTA file.
		# TODO: not implemented.
		def generate_alignments
		end
	end
end
