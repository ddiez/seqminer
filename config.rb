require 'pathname'
require 'common'
module Config

	class General
		include Common
		# Directories.
		attr_accessor :dir_home, :dir_result, :dir_commit, :dir_import, :dir_log, :file_log
		attr_reader :dir_source, :dir_sequence, :dir_model, :dir_pfam, :dir_pfam_current, :dir_config, :db_host, :db_release, :dir_etc, :dir_etc_local
		# Tools directories.
		attr_accessor :dir_hmmer, :dir_blast, :dir_meme, :dir_r
		# Files.
		attr_reader :file_taxon, :file_ortholog

		def _read_project(name)
			if name.nil?
				info
				info "* INFO: no project selected- available projects:"
				info
			end
			p = {}
			p['name'] = name
			p['dir'] = nil
			[@dir_etc, @dir_etc_local].each do |loc|
				info "* file: " + loc + "projects" if ! name
				File.open(loc + "projects").each do |line|
					line.chop!
					project, dir = line.split("\t")
					if name.nil?
						info project + "\t" + dir
					else
						if(project == name)
							p['dir'] = dir
						end
					end
				end
				info if ! name
			end
			
			if name.nil?
				info "* Either choose one of these projects or add a new one\n  to the config files."
				info
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
		
		def _check_project_dir
			if ! dir_home.exist?
				_warn "INFO: project home directory does not exists,", nil 
				_warn "         a basic structure will be created at:", nil
				_warn "         " + dir_home, nil
				_warn "         you need to populate the files taxon.txt and ortholog.txt at etc with", nil
				_warn "         valid values.", nil
				_init_project_dir
			end
		end
		
		def _init_project_dir
			@dir_home.mkpath
			@dir_config.mkpath
			@dir_model.mkpath
			@dir_source.mkpath
			@dir_sequence.mkpath
			@dir_result.mkpath
			@dir_commit.mkpath
			@dir_log.mkpath
			@dir_pfam.mkpath

			# import files from previous release.
			if @dir_import
				# config.
				warn "* import_database: " + dir_import
				["taxon.txt", "ortholog.txt", "family.txt"].each do |f|
					file1 = dir_import + "etc" + f
					file2 = dir_home + "etc" + f
					cmd = "cp -v " + file1 + " " + file2
				system cmd
				end

				# model.
				["Extra.hmm", "hmm", "pssm"].each do |f|
					file1 = @dir_import + "model" + f
					file2 = @dir_model + "."
					cmd = "cp -rfv " + file1 + " " + file2
					system cmd
				end
			
				# source.
				if @import_source
					file1 = dir_import + "source"
					file2 = dir_home + "."
					cmd = "cp -rfv " + file1 + " " + file2
					system cmd
				end

				# pfam.
				file1 = @dir_pfam_current
				file2 = @dir_pfam + "current"
				cmd = "ln -sv " + file1 + " " + file2
				system cmd
			else # otherwise create empty config files.
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
				
				# model.
				(@dir_model + "hmm").mkpath
				(@dir_model + "pssm").mkpath
			end
		end
	
		def initialize(project_name, import_name = nil, import_source = false)
			@dir_etc = File.expand_path(File.dirname(__FILE__))+"/etc/"
			@dir_etc_local = ENV['HOME']+"/.seqminer/"

			p = _read_project(project_name)
			if p['dir'].nil?
				error
				error "unkown project name '" + project_name + "'!\n"
				error ">  check your config file in ~/.seqminer/projects and"
				error ">  the project name in sm_install.rb or sm_search.rb\n"
				error
				exit
			end
			@project = p['name']
			@dir_home = Pathname.new(p['dir'])
				
			if import_name
				pi = _read_project(import_name)
				#warn pi['dir']
				@dir_import = Pathname.new(pi['dir'])
				@import_source = import_source
			else
				@dir_import = nil
			end
			
			_update_variables
			_check_project_dir
		end
		
		def _update_variables
			# Configuration.
			@dir_config = dir_home + "etc"
			@file_taxon = dir_config + "taxon.txt"
			@file_ortholog = dir_config + "ortholog.txt"
		
			# Log.
			@dir_log = dir_home + "log"
			@file_log = dir_log + "log.txt"
			
			# Databases.
			@dir_source = dir_home + "source"
			@dir_sequence = dir_home + "sequence"
			@dir_model = dir_home + "model"
			@dir_pfam = dir_home + "pfam"
			@dir_pfam_home = Pathname.new("/Volumes/Biodev/db/pfam")
			@dir_pfam_current = @dir_pfam_home + "current"
			
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
		
		def file_log=(file)
			@file_log = dir_log + file
		end
		
		def info msg = ""
			_info msg, file_log
		end
			
		def debug
			info "+ Config +"
			info "* dir_home: " + dir_home
			info "* dir_config: " + dir_config
			info "* dir_source: " + dir_source
			info "* dir_sequence: " + dir_sequence
			info "* dir_model: " + dir_model
			info "* dir_pfam: " + dir_pfam
			info "* dir_result: " + dir_result
			info "* dir_commit: " + dir_commit
			info "* dir_hmmer: " + dir_hmmer
			info "* dir_blast: " + dir_blast
			info "* dir_meme: " + dir_meme
			info "* dir_r: " + dir_r
			info "* dir_log: " + dir_log
			info "* file_log: " + file_log
			info "* databases: "
			info
			db_host.each_pair do |db, host|
				info "  -" + db + ":\t" + host + "\t(" + db_release[db] + ")"
			end
			info
		end
	end
end
