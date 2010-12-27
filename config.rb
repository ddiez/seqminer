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

		def _read_project(name)
			r = {}
			File.open("/home/diez/.seqminer/projects").each do |line|
				line.chop!
				project, dir = line.split("\t")
				if(project == name)
					r['name'] = project
					r['dir'] = dir
				end
			end
			r
		end
		
		def _read_tools
			r = {}
			File.open("/home/diez/.seqminer/config/tools").each do |line|
				line.chop!
				tool, dir = line.split("\t")
				r[tool] = dir
			end
			r
		end
	
		def initialize(project_name)
			p = _read_project(project_name)
			@project = p['name']
			# Basedir.
			#@dir_home = Pathname.new("/Volumes/Biodev/projects/vardb/dr-6")
			@dir_home = Pathname.new(p['dir'])
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
			
			@dir_hmmer = Pathname.new("/usr/local/hmmer3/binaries")
			@dir_blast = Pathname.new("/usr/local/blast2/bin")
			@dir_meme = Pathname.new("/usr/local/meme/bin")
			@dir_r = Pathname.new("/usr/bin")

			t = _read_tools
			if ! t["hmmer"].nil?
				@dir_hmmer = Pathname.new(t["hmmer"])
			end	
			if ! t["blast"].nil?
				@dir_blast = Pathname.new(t["blast"])
			end
			if ! t["meme"].nil?
				@dir_meme = Pathname.new(t["meme"])
			end
			if ! t["r"].nil?
				@dir_r = Pathname.new(t["r"])
			end
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
			warn "* dir_commit: " + dir_commit
			warn "* dir_hmmer: " + dir_hmmer
			warn "* dir_blast: " + dir_blast
			warn "* dir_meme: " + dir_meme
			warn "* dir_r: " + dir_r
			warn ""
		end
	end
end
