

module Tools
	include Item
	
	class Tools
		attr_accessor :infile, :outfile, :model
		attr_reader :path, :config
		
		def initialize(options = {:config => nil})
			if options[:config]
				@config = options[:config]
			else
				@config = SeqMiner::Config.new
			end
		end
		
		def tool
			@tool
		end
		
		def debug
			warn "+ Tool +"
			warn "* tool: " + tool
			warn "* path: " + path
			warn "* model: " + model
			warn "* infile: " + infile
			warn "* outfile: " + outfile
			warn ""
		end
	end
	
	class Hmmer < Tools
		def initialize(options = {:config => nil})
			super
		end
		
		def tool=(tool)
			@tool = tool
			case tool
			when 'hmmsearch'
				@path = config.dir_hmmer + tool
			end
		end
		
		def execute
			case tool
			when 'hmmsearch'
				outfile2 = @outfile
				outfile2 = outfile2.sub(/log$/, "txt")
				#warn outfile2
				params = "--domtblout " + outfile2
				cmd = [@path, params, @model, @infile, ">", @outfile]
			when 'hmmscan'
				cmd = [@path]
			end
			cmd = cmd.join(" ")
			res = system cmd
		end
	end
	
	class Blast < Tools
		def initialize(options = {:config => nil})
			super
		end
		
		def execute
			case tool
			when 'blastall'
				params = ""
				cmd = [path, params, model, infile, ">", outfile]
			when 'blastpgp'
			end
			cmd = cmd.join(" ")
			res = system cmd
		end
	end
end
