require 'Pathname'

module Config
	# Directories.
	attr_accessor :dir_home
	attr_reader :dir_source, :dir_genome, :dir_model, :dir_db, :dir_config, :dir_result_base, :dir_result
	# Tools directories.
	attr_accessor :dir_hmmer, :dir_blast
	# Files.
	attr_reader :file_taxon, :file_ortholog

	def initialize
		# Basedir.
		@dir_home = Pathname.new("/Volumes/Biodev/projects/vardb")
		update
	end
	
	def update
		# Configuration.
		@dir_config = dir_home + "etc"
		@file_taxon = dir_config + "taxon.txt"
		@file_ortholog = dir_config + "ortholog.txt"
		
		# Databases.
		@dir_db = dir_home + "db"
		@dir_genome = dir_db + "genome"
		@dir_model = dir_db + "model"
		@dir_source = dir_db + "source"
		
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
		puts "* dir_result: " + dir_result
	end
end
