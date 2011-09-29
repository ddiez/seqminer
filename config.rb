require 'pathname'

module Config
	class General
		# Directories.
		attr_accessor :dir_home, :dir_result, :dir_commit
		attr_reader :dir_source, :dir_sequence, :dir_model, :dir_pfam, :dir_pfam_current, :dir_config, :db_host, :db_release, :dir_etc, :dir_etc_local
		# Tools directories.
		attr_accessor :dir_hmmer, :dir_blast, :dir_meme, :dir_r
		# Files.
		attr_reader :file_taxon, :file_ortholog

		def _read_project(name)
			if name.nil?
				puts "* no project selected. listing all projects in config files:"
				puts
			end
			p = {}
			p['name'] = name
			p['dir'] = nil
			[@dir_etc, @dir_etc_local].each do |loc|
				File.open(loc + "projects").each do |line|
					line.chop!
					project, dir = line.split("\t")
					if name.nil?
						puts project + "\t" + dir
					else
						if(project == name)
							p['dir'] = dir
						end
					end
				end
			end
			if name.nil?
				puts "exiting..."
				exit
			else
				p
			end
		end
		
		def _read_tools
			r = {}
			[@dir_etc, @dir_etc_local].each do |loc|
				File.open(loc + "config/tools").each do |line|
					line.chop!
					tool, dir = line.split("\t")
					if dir == "-"
						r[tool] = ""
					else
						r[tool] = dir
					end
				end
			end
			r
		end
		
		def _read_databases
			h = {} # host
			r = {} # release
			[@dir_etc, @dir_etc_local].each do |loc|
				File.open(loc + "config/databases").each do |line|
					line.chop!
					db, rel, host = line.split("\t")
					h[db] = host
					r[db] = rel
				end
			end
			[h, r]
		end
		
		def _check_project_dir(dir)
			if ! dir.exist?
				#puts "ERROR: project directory does not exists, use install option to create a basic structure."
				#exit
				puts "WARNING: project directory does not exists," 
				puts "         a basic structure will be created at:"
				puts "         " + dir
				puts "         you need to populate the files taxon.txt and ortholog.txt at etc with"
				puts "         valid values."
				_init_project_dir
			end
		end
		
		def _init_project_dir
			@dir_home.mkpath
			@dir_config.mkpath
			# taxon file.
			File.open(@dir_config + "taxon.txt", 'w')  do |f|
				f.puts("# taxon file")
			end
			# ortholog file.
			File.open(@dir_config + "ortholog.txt", 'w')  do |f|
				f.puts("# ortholog file")
			end
			# family file.
			File.open(@dir_config + "family.txt", 'w')  do |f|
				f.puts("# family file")
			end
			@dir_source.mkpath
			@dir_sequence.mkpath
			@dir_result.mkpath
		end
	
		def initialize(project_name)
			@dir_etc = File.expand_path(File.dirname(__FILE__))+"/etc/"
			@dir_etc_local = ENV['HOME']+"/.seqminer/"
			p = _read_project(project_name)
			if p['dir'].nil?
				puts
				puts "ERROR: unkown project name '" + project_name + "'!"
				puts
				puts ">  check your config file in ~/.seqminer/projects and"
				puts ">  the project name in sm_install.rb or sm_search.rb"
				puts
				exit
			end
			@project = p['name']
			# Basedir.
			#@dir_home = Pathname.new("/Volumes/Biodev/projects/vardb/dr-6")
			@dir_home = Pathname.new(p['dir'])
			update
			_check_project_dir(@dir_home)
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
			
			(@db_host, @db_release) = _read_databases
			
			# Results.
			@dir_result = dir_home + "result"
			
			# Tools.
			# TODO: alternative define them as "" and hope them to be in the PATH.		
			@dir_hmmer = Pathname.new("/usr/local/bin")
			@dir_blast = Pathname.new("/usr/local/bin")
			@dir_meme = Pathname.new("/usr/local/bin")
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
			warn "* databases: "
			warn ""
			db_host.each_pair do |db, host|
				puts "  -" + db + ":\t" + host + "\t(" + db_release[db] + ")"
			end
			warn ""
		end
	end
end
