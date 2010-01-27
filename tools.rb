require 'SeqMiner'

module Tools
	
	class Tools
		attr_accessor :infile, :outfile, :tool
		attr_reader :path, :config
		
		def initialize(options = {:config => nil})
			if options[:config]
				@config = options[:config]
			else
				@config = SeqMiner::Config.new
			end
		end
		
		def tool=(tool)
			@tool = tool
			case tool
			when 'hmmsearch'
				@path = config.dir_hmmer + tool
			when 'tblastn'
				@path = config.dir_blast + tool
			when 'psiblast'
				@path = config.dir_blast + tool
			when 'makeblastdb'
				@path = config.dir_blast + tool
			end
		end
	end
	
	class Hmmer < Tools
		attr_accessor :model, :table_file
		
		def initialize(options = {:config => nil})
			super
			@model = "_undef_"
			@infile = "_undef_"
			@table_file = "_undef_"
		end
		
		def outfile=(file)
			@outfile = file
			@table_file = outfile.sub(/\.log$/, "txt")
		end
		
		def execute
			case tool
			when 'hmmsearch'
				params = "--domtblout " + table_file
				cmd = [path, params, model, infile, ">", outfile]
			when 'hmmscan'
				params = ""
				cmd = [path, params, model, infile, ">", outfile]
			when 'hmmalign'
				params = ""
				cmd = [path, params, model, infile, ">", outfile]
			end
			cmd = cmd.join(" ")
			res = system cmd
		end
		
		def debug
			warn "+ Tool +"
			warn "* tool: " + tool.to_s
			warn "* path: " + path.to_s
			warn "* model: " + model.to_s
			warn "* infile: " + infile.to_s
			warn "* outfile: " + outfile.to_s
			warn "* table_file: " + table_file.to_s
			warn ""
		end
	end
	
	class Blast < Tools
		attr_accessor :seed_file, :pssm_file, :db, :dbtype, :dbtitle
		def initialize(options = {:config => nil})
			super
		end
		
		def execute
			case tool
			when 'tblastn'
				params = "-outfmt 7 -num_threads 8"
				cmd = [path, params, "-db", db, "-in_pssm", pssm_file, ">", outfile]
			when 'psiblast'
				params = "-num_iterations 3 -inclusion_ethresh 0.0001 -num_threads 8"
				cmd = [path, params, "-db", db, "-out_pssm", pssm_file, "-query", seed_file, ">", outfile] 
			when 'makeblastdb'
				params = "-hash_index -parse_seqids"
				@dbtitle = outfile if ! dbtitle
				cmd = [path, params, "-in", infile, "-out", outfile, "-dbtype", dbtype, "-title", dbtitle]
			end
			cmd = cmd.join(" ")
			res = system cmd
			res
		end
		
		def debug
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
			warn ""
		end
	end
end
