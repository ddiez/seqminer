require 'pathname'

module Config
	class General
		# Directories.
		attr_accessor :dir_home, :dir_result, :dir_commit
		attr_reader :dir_source, :dir_sequence, :dir_model, :dir_pfam, :dir_pfam_current, :dir_config
		# Tools directories.
		attr_accessor :dir_hmmer, :dir_blast, :dir_meme, :dir_r
		# Files.
		attr_reader :file_taxon, :file_ortholog
	
		def initialize
			# Basedir.
			@dir_home = Pathname.new("/Volumes/Biodev/projects/vardb/dr-6")
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
			@dir_pfam_current = @dir_pfam + "current"
			
			# Results.
			@dir_result = dir_home + "result"
			
			# Tools.
			#@dir_hmmer = Pathname.new("/Users/diez/local/hmmer3/bin")
#			@dir_hmmer = Pathname.new("/Users/diez/local/hmmer-3.0b2/src")
#			@dir_blast = Pathname.new("/usr/local/ncbi/blast/bin")
#			@dir_meme = Pathname.new("/Users/diez/local/meme/bin")
#			@dir_r = Pathname.new("/usr/bin")
			
			@dir_hmmer = Pathname.new("/home/diez/local/hmmer3/binaries")
			@dir_blast = Pathname.new("/home/diez/local/blast2/bin")
			@dir_meme = Pathname.new("/Users/diez/local/meme/bin")
			@dir_r = Pathname.new("/usr/bin")
			
			# Commit
			@dir_commit = dir_home + "commit"
		end
		
		def basedir=(dir)
			@dir_home = Pathname.new(dir).expand_path
			update
		end
		
		def basedir
			@dir_home
		end
	
		def debug
			warn "+ Config +"
			warn "* dir_home: " + dir_home
			warn "* dir_config: " + dir_config
			warn "* dir_source: " + dir_source
			warn "* dir_sequence: " + dir_sequence
			warn "* dir_model: " + dir_model
			warn "* dir_pfam: " + dir_pfam
			warn "* dir_result: " + dir_result
			warn "* dir_hmmer: " + dir_hmmer
			warn "* dir_blast: " + dir_blast
			warn "* dir_meme: " + dir_meme
			warn "* dir_commit: " + dir_commit
			warn ""
		end
	end
end
