

module Tools
	include Item

	class Tools
		attr_accessor :infile, :outfile, :model
		attr_reader :path, :config
		
		def initialize(options = {:config => nil})
			if ! options[:config]
				@config = SeqMiner::Config.new
			else
				@config = options[:config]
			end
		end
		
		def tool=(tool)
			case tool
			when "hmmsearch"
				@path = config.dir_hmmer + tool
			end
			@tool = tool
		end
		
		def tool
			@tool
		end
		
		def execute
			case @tool
			when "hmmsearch"
				outfile2 = @outfile
				outfile2 = outfile2.sub(/log$/, "txt")
				#warn outfile2
				params = "--domtblout " + outfile2
				cmd = [@path, params, @model, @infile, ">", @outfile]
			end
			cmd = cmd.join(" ")
			res = system cmd
		end
		
		def debug
			warn "+ Tool +"
			warn "* infile: " + infile
			warn "* outfile: " + outfile
			warn "* model: " + model
			warn "* path: " + path
			warn "* tool: " + tool
			warn ""
		end
	end
	
	class Hmmer < Tools
		def initialize(options)
			super
		end		
	end
end
