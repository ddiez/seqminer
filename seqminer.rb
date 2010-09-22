# SeqMiner is a tool for mining sequence information. It aims to
# help detect sequences belonging to specific protein families.
#
# Author::    Diego Diez  (mailto:diez@kuicr.kyoto-u.ac.jp)
# Copyright:: Copyright (c) 2010
# License::   Distributes under the same terms as Ruby

require 'pathname'

require 'config'
require 'common'
require 'taxon'
require 'ortholog'
require 'search'
require 'scan'
require 'result'
require 'download'
require 'tools'
require 'queue'

module SeqMiner
	class Install
		include Common

		attr_reader :project, :config, :taxon, :ortholog

		def initialize(options = {:config => nil})
			
			if ! options[:config]
				@config = Config::General.new
			else
				@config = options[:config]
			end
			
			@taxon = Taxon::Set.new(options = {:config => config})
			@ortholog = Ortholog::Set.new(options = {:config => config})
		end
		
		def install
			create_dir_structure
			update_databases
		end
		
		def create_dir_structure
			create_base_dir
			config.dir_source.mkpath
			config.dir_model.mkpath
			config.dir_sequence.mkpath
			config.dir_pfam.mkpath
			config.dir_result.mkpath
			config.dir_config.mkpath
			config.dir_commit.mkpath
		end
		
		def create_base_dir
			if config.dir_home.exist?
				warn "ERROR: target directory already exists. Incompatible with instalation."
				exit
			else
				warn "* creating dir_home: " + config.dir_home
				config.dir_home.mkpath
			end
		end
		
		def update_databases
			update_pfam
			process_pfam
			update_sequences
			process_sequences
		end
		
		def update_pfam
			d = Download::Pfam.new(options = {:config => config})
			d.update
		end
		
		def update_sequences
			d = Download::Set.new(taxon, options = {:config => config})
			d.download
		end
		
		def process_pfam
			# Gunzip .gz files.
			config.dir_pfam_current.each_entry do |entry|
				file = config.dir_pfam_current + entry
				if file.file?
					if file.extname == ".gz"
						puts "* gunzip: " + file
						res = system("gunzip #{file}")
					end
				end
			end
			
			# Press .hmm files.
			config.dir_pfam_current.each_entry do |entry|
				file = config.dir_pfam_current + entry
				if file.file?
					if file.extname == ".hmm"
						puts "* hmmpress: " + file
						ts = Tools::Hmmer("hmmpress")
						ts.infile = file
						ts.debug
						res = ts.execute
						_check_result(res, true, "trying to overwrite previous pressing [SKIPPED]")
					end
				end
			end
		end
		
		def process_sequences
			taxon.each_value do |t|
				case t.type
				when 'spp'
					process_spp(t)
				when 'clade'
					process_clade(t)
				end
			end
		end
		
		def process_directories
			taxon.each_taxon do |t|
				process_blast(t)
			end
		end
		
		# This method will generate the approapriate databases for use with BLAST-like programs.
		def process_blast(t)
			warn "* formatting: " + t.name
			dir = config.dir_sequence + t.name
			Dir.chdir(dir)
			
			ts = Tools::Blast.new('makeblastdb', options = {:config => config}) 
			
			["gene", "cds", "protein", "6frame", "genome"].each do |type|
				next if type == "genome" and t.type != "spp"
				ts.outfile = type
				ts.dbtitle = type
				ts.dbtype = "nucl"
				ts.dbtype = "prot" if type == "protein" or type == "6frame"
				ts.infile = type + ".fa"
				ts.debug
				res = ts.execute
				_check_result(res)
			end
		end
		
		def process_spp(t)
			puts "* source: " + t.source
			puts "* dir: " + (config.dir_source + t.name)
			
			case t.source
			when "plasmodb", "giardiadb", "tritrypdb"
				puts "* parser: eupathdb"
				if t.name == "trypanosoma.cruzi_CL_Brener"
					p = Parser::Eupathdb.new(t, options = {:config => config, :subtype => "Esmeraldo"})
				else
					p = Parser::Eupathdb.new(t, options = {:config => config})
				end
			when "broad"
				p = Parser::Broad.new(t, options = {:config => config})
			when "ncbi"
				puts "* parser: refseq"
				p = Parser::Refseq.new(t, options = {:config => config})
			end
			g = p.parse
			g.debug
			
			outdir = config.dir_sequence + t.name
			outdir.mkpath if ! outdir.exist?
			warn "* writing gene FASTA file"
			g.write_fasta("gene", outdir + "gene.fa")
			warn "* writing CDS FASTA file"
			g.write_fasta("cds", outdir + "cds.fa")
			warn "* writing protein FASTA file"
			g.write_fasta("protein", outdir + "protein.fa")
			warn "* writing 6frame FASTA file"
			g.write_fasta("6frame", outdir + "6frame.fa")
			warn "* writing genome FASTA file"
			g.write_fasta("genome", outdir + "genome.fa")
			warn "* writing genome TABLE file"
			g.write_table(outdir + "genome.txt")
		end
		
		def process_clade(t)
			puts "* source: " + t.source
			puts "* dir: " + (config.dir_source + t.name)
			
			p = Parser::GenbankIsolate.new(t, options = {:config => config})
			i = p.parse
			
			outdir = config.dir_sequence + t.name
			outdir.mkpath if ! outdir.exist?
			
			warn "* writing gene FASTA file"
			i.write_fasta("gene", outdir + "gene.fa")
			warn "* writing CDS file"
			i.write_fasta("cds", outdir + "cds.fa")
			warn "* writing protein FASTA file"
			i.write_fasta("protein", outdir + "protein.fa")
			warn "* writing 6frame FASTA file"
			i.write_fasta("6frame", outdir + "6frame.fa")
			warn "* writing isolate FASTA file"
			i.write_fasta("isolate", outdir + "isolate.fa")
			warn "* writing isolate TABLE file"
			i.write_table(outdir + "isolate.txt")
		end
		
		def update_model
			update_hmm
			update_pssm
		end
		
		def update_hmm
			ortholog.each_ortholog do |o|
				o.debug
				hr = Tools::Hmmer.new('hmmfetch', options = {:config => config})
				hr.infile = config.dir_pfam + "current" + "Pfam-A.hmm"
				hr.model = o.hmm
				hr.outfile = config.dir_model + "hmm" + o.hmm
				hr.debug
				res = hr.execute
				if (! res) then
					hr.infile = config.dir_model + "Extra.hmm"
					res = hr.execute
					_check_result(res)
				else
					_check_result(res)
				end
			end
		end
		
		# This method computes the best hit for a series of genomic searches belonging to the same species and
		# then returns the best hit (for protein searched) as seed for a PSI-Blast search.
		def update_pssm
			typeset = Search::TypeSet.new
			ortholog.each_ortholog do |o|
				o.debug
				rs = Result::Set.new
				warn "* computing best hit"
				taxon.each_taxon do |t|
					next if t.type != 'spp'
					typeset.each_value do |type|
						next if type.name != "protein"
						sid = t.name + "-" + o.name + "-" + type.name
						file = config.dir_result + "genome/search" + o.name + (sid + ".txt")
						p = Result::HmmerParser.new(options = {:config => config, :taxon => t, :ortholog => o, :tool => "hmmsearch"})
						p.file = file
						p.result_id = sid
						p.type = type
						r = p.parse
						rs << r
					end
				end
				#rs.debug
				rs.filter_by_eval(0.001)
				rs.clean_up
				next if rs.length == 0
				#o.debug
				#rs.debug
				bh = rs.best_hit
				bh.debug
				bh.taxon.debug
				
				# Store the SEED sequence.
				warn "* updating seed sequences"
				sdb = Sequence::Set.new(bh.taxon.name, "protein", options = {:config => config})
				seq = sdb.get_seq_by_acc(bh.id)
				dir = config.dir_model + "pssm"
				dir.mkpath if ! dir.exist?
				file = dir + (bh.ortholog.name + ".seed")
				fo = File.new(file, "w")
				fo.puts seq.seq.to_fasta(seq.definition, 60)
				fo.close
				
				# Run the search with the SEED and the genome.
				warn "* computing PSSM model for Blast+"
				pssm_file = dir + (bh.ortholog.name + ".pssm")
				pgp_file = dir + (bh.ortholog.name + ".pgp")
				ts = Tools::Blast.new('psiblast', options = {:config => config})
				ts.db = config.dir_sequence + bh.taxon.name + "protein"
				ts.seed_file = file
				ts.pssm_file = pssm_file
				ts.outfile = pgp_file
				ts.debug
				res = ts.execute
				_check_result(res)
			end
		end
	end
	
	class Pipeline
		include Common

		attr_accessor :taxon, :ortholog, :search, :result, :scan_result, :scan
		attr_reader :config
		
		def initialize(options = {:config => nil})

			if options[:config]
				@config = options[:config]
			else
				@config = Config::General.new
			end

			config.debug

			@taxon = Taxon::Set.new(options = {:config => config})
			@ortholog = Ortholog::Set.new(options = {:config => config})
			@type = Search::TypeSet.new(options = {:config => config})
			build_search
			build_scan
			
			@dir_initialized = false
		end

		def dir_initialized?
			@dir_initialized
		end
		
		def dir_initialize
			dir_level1 = ['genome', 'isolate']
			dir_level2 = ['search', 'sequence', 'fasta', 'scan', 'domain']
			
			warn "+ CREATE RESULT DIR STRUCTURE +"
			#warn "* " + dir_result
			#dir_result.mkpath
			dir_level1.each do |level1|
				dir_level2.each do |level2|
					ortholog.items.each_value do |ortholog|
						dir = config.dir_result + level1 + level2 + ortholog.name
						warn "* " + dir
						dir.mkpath if ! dir.exist?
					end
				end
			end
		end

		def run_all
			dir_initialize if ! dir_initialized?
			run_search
			get_search_results
			write_nelson
			write_fasta
			run_scan
		end
		
		def build_search
			ps = Search::Parameter.new(@taxon, @ortholog, @type)
			@search = Search::Set.new(ps, options = {:config => config})
		end
		
		# Initializes the result directory structure if needed, then performs the searches.
		def run_search
			search.search
		end
		
		def build_scan
			ps = Search::Parameter.new(@taxon, @ortholog, @type)
			@scan = Scan::Set.new(ps, options = {:config => config})
		end

		# Search Pfam domains in protein sequence.
		def run_scan
			scan.scan
		end
		
		#
		def get_scan_results(eval = 0.01)
			@scan_result = scan.parse 
			scan_result.filter_domain_by_eval(eval)
			scan_result.clean_up
		end
		
		# Parses the HMMER files, performs auto_merge and obtains the results (given an Evalue thereshold).
		def get_search_results(eval = 0.001)
			@result = search.parse
			@result = result.auto_merge
			result.filter_by_eval(eval)
			result.clean_up
		end

		def write_nelson
			if result.nil?
				get_search_results
			end
			result.write_nelson
		end
		
		def write_domain
			if scan_result.nil?
				get_scan_results
			end
			scan_result.write_domain
		end

		# Pipeline-wise write_fasta.
		def write_fasta
			if result.nil?
				get_search_results
			end
			result.write_fasta
		end
		
		# Pipeline-wise report.
		def report(completeness = 1)
			if result.nil?
				get_search_results
			end
			result.report(cut = completeness)
		end
		
		# Pipeline-wise summary report.
		def report_summary
			if result.nil?
				get_search_results
			end
			result.report_summary
		end
		
		# This function automatically generate protein alignments by concatenating the FASTA files for protein
		# for sequences in the same gene family. Then runs Clustalw-mpi on the concatenated FASTA file.
		# TODO: not implemented.
		def generate_alignments
		end
	end

	class Stat
		attr_accessor :taxon, :ortholog, :family
		attr_reader :config
		
		def initialize(options = {:config => nil})

			if options[:config]
				@config = options[:config]
			else
				@config = Config::General.new
			end

			@taxon = Taxon::Set.new(options = {:config => config})
			@ortholog = Ortholog::Set.new(options = {:config => config})
			@family = Family::Set.new(options = {:config => config})
		end

		def result_stat
			puts "Ortholog\tTaxon\tType\tCount"
			ortholog.each_ortholog do |o|
				taxon.each_taxon do |t|
					case t.type
					when 'spp'
						file = config.dir_result + "genome/sequence" + o.name + (t.name + "-" + o.name + ".txt")
					when 'clade'
						file = config.dir_result + "isolate/sequence" + o.name + (t.name + "-" + o.name + ".txt")
					end
					if file.exist?
						n = 0
						File.open(file, "r").each_line do |line|
							n += 1
						end
						puts o.name + "\t" + t.name + "\t" + t.type + "\t" + n.to_s
					end
				end
			end
		end
		
		def sequence_stat
			ortholog.each_ortholog do |o|
				taxon.each_taxon do |t|
					r = Parser::Nelson.new(t, o, options = {:config => config})
				end
			end
		end
		
		def family_stat
			family.each_family do |f|
				ts = Taxon::Set.new(options = {:config => config})
				ts.filter_by_name(f.taxon)
				o = ortholog.get_ortholog_by_name(f.ortholog)
				ts.each_taxon do |taxon|
					r = Parser::Nelson.new(taxon, o, options = {:config => config})
				end
			end
		end
		
		def source_stat
			puts "Taxon\tnuccore_pass\tnuccore_skip\tnucest_pass\tnucest_skip\taccepted"
			taxon.each_taxon do |t|
				next if t.type == "spp"
				n = {}
				["accepted", "nuccore_pass", "nuccore_skip", "nucest_pass", "nucest_skip"].each do |f|
					n[f] = 0 if ! n[f]
					file = config.dir_source + t.name + (f + ".txt")
					if file.exist?
						File.open(file, "r").each_line do |line|
							n[f] += 1
						end
					end
				end
				puts t.name + "\t" + n["nuccore_pass"].to_s + "\t" + n["nuccore_skip"].to_s + "\t" + \
					n["nucest_pass"].to_s + "\t" + n["nucest_skip"].to_s + "\t" + n["accepted"].to_s
			end
		end

		def debug
			config.debug
		end
	end
	
	# This class helps commit the file to a given directory, either for uploading into the database or othe uses.
	class Commit
		attr_reader :config, :family
		
		def initialize(options = {:config => nil})

			if options[:config]
				@config = options[:config]
			else
				@config = Config::General.new
			end

			@family = Family::Set.new(options = {:config => config})
		end
		
		def commit
			if ! config.dir_commit.exist?
				warn "* creating output directory: " + config.dir_commit
				config.dir_commit.mkpath
			end
			
			
			["sequence", "domain"].each do |type|
				outdir = config.dir_commit + type
				if ! outdir.exist?
					outdir.mkpath
				end
			
				family.each_family do |f|
					ts = Taxon::Set.new(options = {:config => config})
					ts.filter_by_name(f.taxon)
					ts.each_taxon do |taxon|
						case taxon.type
						when 'spp'
							dir = config.dir_result + "genome" + type + f.ortholog
						when 'clade'
							dir = config.dir_result + "isolate" + type + f.ortholog
						end
						file = dir + (taxon.name + "-" + f.ortholog + ".txt")
						warn "* commiting file: " + file
						if file.exist?
							File.cp(file, outdir)
						else
							raise("!!! file " + file + " does not exist!")
						end
					end
				end
			end
		end
		
		def filter
			family.each_family do |f|
				f.debug
			end
		end
		
		def stat_sequences
			family.each_family do |f|
				#outdir = config.dir_commit + f.ortholog
				outdir = config.dir_commit
				if ! outdir.exist?
					raise "ERROR: commit directory does not exist!"
				end
				ts = Taxon::Set.new(options = {:config => config})
				ts.filter_by_name(f.taxon)
				ts.each_taxon do |taxon|
					case taxon.type
					when 'spp'
						dir = config.dir_result + "genome/fasta" + f.ortholog
					when 'clade'
						dir = config.dir_result + "isolate/fasta" + f.ortholog
					end
					gene_file = dir + (taxon.name + "-" + f.ortholog + "_gene.fa")
					protein_file = dir + (taxon.name + "-" + f.ortholog + "_protein.fa")
					if gene_file.exist?
						system "grep \">\" #{gene_file} >> #{outdir}/gene_list.txt"
					else
						raise("!!! file " + gene_file + " does not exist!")
					end
					if gene_file.exist?
						system "grep \">\" #{protein_file} >> #{outdir}/protein_list.txt"
					else
						raise("!!! file " + protein_file + " does not exist!")
					end
				end
			end
		end
		
		def debug
			config.debug
		end
		
		# This is done now here, but it should probably be done in the Pipeline.
		def align
			n = 0
			q = Queue.new
			family.each_family do |f|
				outdir = config.dir_commit + "alignment"
				if ! outdir.exist?
					#raise "ERROR: commit directory does not exist!"
					outdir.mkpath
				end
				ts = Taxon::Set.new(options = {:config => config})
				ts.filter_by_name(f.taxon)
				ts.each_taxon do |taxon|
					case taxon.type
					when 'spp'
						dir = config.dir_result + "genome/fasta" + f.ortholog
					when 'clade'
						dir = config.dir_result + "isolate/fasta" + f.ortholog
					end
					["protein", "cds"].each do |st|
						infile = dir + (taxon.name + "-" + f.ortholog + "_" + st + ".fa")
						outfile = outdir + (taxon.name + "-" + f.ortholog + "_" + st + ".faln")
						if infile.exist?
							n += 1
							j = Job.new(n)
							#j.log = "* aligning " + infile
							j.cmd = "mafft --quiet --auto #{infile} > #{outfile}"
							q << j
						else
							raise("!!! file " + infile + " does not exist!")
						end
					end
				end
			end
			q.ncpu = 16
			q.debug
			q.run
		end
	end

	class Analysis
		attr_reader :config
		
		def initialize(options = {:config => nil})
			if options[:config]
				@config = options[:config]
			else
				@config = Config::General.new
			end
		end

		# This method computes the bigram for each domain in all sequence sets.
		def bigram

		end
	end
end
