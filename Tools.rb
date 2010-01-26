require 'SeqMiner'

module Tools
	
	class Tools
		attr_accessor :outfile, :tool
		attr_reader :path, :config
		
		def initialize(options = {:config => nil})
			if options[:config]
				@config = options[:config]
			else
				@config = SeqMiner::Config.new
			end
			
			@tool = "_undef_"
			@path = "_undef_"
			@outfile = "_undef_"
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
		attr_accessor :model, :infile, :table_file
		
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
			warn "* tool: " + tool
			warn "* path: " + path
			warn "* model: " + model
			warn "* infile: " + infile
			warn "* outfile: " + outfile
			warn "* table_file: " + table_file
			warn ""
		end
	end
	
	class Blast < Tools
		attr_accessor :seed_file, :pssm_file, :db
		def initialize(options = {:config => nil})
			super
		end
		
		def execute
			case tool
			when 'tblastn'
				params = "-outfmt 7"
				cmd = [path, params, "-db", db, "-in_pssm", pssm_file, ">", outfile]
			when 'psiblast'
				params = "-num_iterations 3 -inclusion_ethresh 0.0001 -num_threads 8"
				cmd = [path, params, "-db", db, "-out_pssm", pssm_file, "-query", seed_file, ">", outfile] 
			when 'makeblastdb'
				cmd = [path]
			end
			cmd = cmd.join(" ")
			res = system cmd
			res
		end
		
		def debug
			warn "+ Tool +"
			warn "* tool: " + tool
			warn "* path: " + path
			warn "* model: " + pssm_file
			warn "* db: " + db
			warn "* seed_file: " + seed_file
			warn "* outfile: " + outfile
			warn ""
		end
	end
end
