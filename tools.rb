# SeqMiner is a tool for mining sequence information. It aims to
# help detect sequences belonging to specific protein families.
#
# Author::    Diego Diez  (mailto:diez@kuicr.kyoto-u.ac.jp)
# Copyright:: Copyright (c) 2010
# License::   Distributes under the same terms as Ruby

require 'config'

module Tools
	
	class Tools
		attr_accessor :infile, :outfile, :tool, :cmd
		attr_reader :path, :config, :parameters
		
		def initialize(tool, options = {:config => nil, :project => nil})
			if options[:config]
				@config = options[:config]
			else
				@config = Config::General.new(options[:project])
			end
			
			@tool = tool
		end
		
		def execute
			res = system cmd
			res
		end
	end
	
	class Hmmer < Tools
		attr_accessor :model, :table_file
		
		def initialize(tool, options = {:config => nil})
			super
			
			@path = config.dir_hmmer + tool
			
			case tool
			when 'hmmsearch'
				@parameters = ""
			when 'hmmscan'
				@parameters = ""
			when 'hmmalign'
				@parameters = ""
			when 'hmmpress'
				@parameters = ""
			when 'hmmfetch'
				@parameters = ""
			end
		end
		
		def outfile=(file)
			@outfile = file
			@table_file = outfile.sub(/\.log$/, ".txt")
		end
		
		def execute
			build_cmd
			super
		end
		
		def build_cmd
			case tool
			when 'hmmsearch'
				cmd = [path, parameters, "--domtblout", table_file, model, infile, ">", outfile]
			when 'hmmscan'
				cmd = [path, parameters, "--domtblout", table_file, model, infile, ">", outfile]
			when 'hmmalign'
				cmd = [path, parameters, model, infile, ">", outfile]
			when 'hmmpress'
				cmd = [path, parameters, model, infile, ">", outfile]
			when 'hmmfetch'
				cmd = [path, parameters, infile, model, ">", outfile]
			end
			@cmd = cmd.join(" ")
		end
		
		def debug
			build_cmd
			warn "+ Tool +"
			warn "* tool: " + tool.to_s
			warn "* path: " + path.to_s
			warn "* model: " + model.to_s
			warn "* infile: " + infile.to_s
			warn "* outfile: " + outfile.to_s
			warn "* table_file: " + table_file.to_s
			warn "* parameters: " + parameters.to_s
			warn "* cmd: " + cmd.to_s
			warn ""
		end
	end
	
	class Blast < Tools
		attr_accessor :seed_file, :pssm_file, :db, :dbtype, :dbtitle
		def initialize(tool, options = {:config => nil})
			super
			
			@path = config.dir_blast + tool
			
			case tool
			when 'tblastn'
				@parameters = "-outfmt \"7 std sframe\" -num_descriptions 100000 -num_threads 8"
			when 'psiblast'
				@parameters = "-num_iterations 3 -inclusion_ethresh 0.0001 -num_threads 8" 
			when 'makeblastdb'
				@parameters = "-hash_index -parse_seqids"
			end
		end
		
		def execute
			build_cmd
			super
		end
		
		def build_cmd
			case tool
			when 'tblastn'
				cmd = [path, parameters, "-db", db, "-in_pssm", pssm_file, ">", outfile]
			when 'psiblast'
				cmd = [path, parameters, "-db", db, "-out_pssm", pssm_file, "-query", seed_file, ">", outfile] 
			when 'makeblastdb'
				@dbtitle = outfile if ! dbtitle
				cmd = [path, parameters, "-in", infile, "-out", outfile, "-dbtype", dbtype, "-title", "\"" + dbtitle + "\""]
			end
			@cmd = cmd.join(" ")
		end
		
		def debug
			build_cmd
			warn "+ Tool +"
			warn "* tool: " + tool.to_s
			warn "* path: " + path.to_s
			warn "* db: " + db.to_s
			warn "* dbtype: " + dbtype.to_s
			warn "* dbtitle: " + dbtitle.to_s
			warn "* infile: " + infile.to_s
			warn "* outfile: " + outfile.to_s
			warn "* seed_file: " + seed_file.to_s
			warn "* model: " + pssm_file.to_s
			warn "* parameters: " + parameters.to_s
			warn "* cmd: " + cmd.to_s
			warn ""
		end
	end
	
	class Meme < Tools
		attr_accessor :outdir, :db, :query, :target
		def initialize(tool, options = {:config => nil})
			super
			
			@path = config.dir_meme + tool
			
			case tool
			when 'meme'
				@parameters = "-text"
			when 'mast'
				@parameters = "-text" 
			when 'tomtom'
				@parameters = "-text"
			end
		end
		
		def execute
			build_cmd
			super
		end
		
		def build_cmd
			case tool
			when 'meme'
				cmd = [path, infile, "-o", outdir, parameters]
			when 'mast'
				cmd = [path, infile, "-d", db, parameters] 
			when 'tomtom'
				cmd = [path, parameters, "-query", query, "-target", target]
			end
			@cmd = cmd.join(" ")
		end
		
		def debug
			build_cmd
			warn "+ Tool +"
			warn "* tool: " + tool.to_s
			warn "* path: " + path.to_s
			warn "* infile: " + infile.to_s
			warn "* outdir: " + outdir.to_s
			warn "* db: " + db.to_s
			warn "* query: " + query.to_s
			warn "* target: " + target.to_s
			warn "* parameters: " + parameters.to_s
			warn "* cmd: " + cmd.to_s
			warn ""
		end
	end
	
	class R < Tools
		attr_accessor :script
		
		def initialize(tool = "R", options = {:config => nil})
			super
			
			@path = config.dir_r + tool
			@parameters = ""
		end
		
		def execute
			build_cmd
			super
		end
		
		def build_cmd
			# TODO: how to pass the script as stdin?
			# For example, using pipes:
#			def send_message message, netbiosname
#			  IO.popen "smbclient -M #{netbiosname}", 'w' do |io|
#			    message.each_line do |line|
#			      io.write line
#			    end
#			  end
#			  raise 'smbclient failed' unless $?.success?
#			end
			cmd = [path, parameters, "<", script]
			@cmd = cmd.join(" ")
		end
		
		def debug
			build_cmd
			warn "+ Tool +"
			warn "* tool: " + tool.to_s
			warn "* path: " + path.to_s
			warn "* infile: " + infile.to_s
			warn "* parameters: " + parameters.to_s
			warn "* cmd: " + cmd.to_s
			warn ""
		end
	end
end
