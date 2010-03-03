# SeqMiner is a tool for mining sequence information. It aims to
# help detect sequences belonging to specific protein families.
#
# Author::    Diego Diez  (mailto:diez@kuicr.kyoto-u.ac.jp)
# Copyright:: Copyright (c) 2010
# License::   Distributes under the same terms as Ruby

require 'config'
require 'item'
require 'genome'
require 'sequence'
require 'taxon'
require 'ortholog'
require 'family'

module Result
	include Item
	
	class Domain < Item
		attr_accessor :score, :eval, :bias
		
		def initialize(id)
			super
		end
		
		def each_domainhit
			each_value do |value|
				yield value
			end
		end
		
		def has_complete?(cut = 1)
			each_domainhit do |dh|
				return true if dh.complete?(cut)
			end
			return false
		end
		
		def has_fragment?(cut = 1)
			each_domainhit do |dh|
				return true if ! dh.complete?(cut)
			end
			return false
		end
		
		def debug
			warn "+ Domain +"
			warn "* id: " + id.to_s
			warn "* length: " + length.to_s
			warn "* eval: " + eval.to_s
			warn "* score: " + score.to_s
			warn "* bias: " + bias.to_s
		end
	end

	class DomainHit < Item
		attr_accessor :ceval, :ieval, :score, :bias, :aln_from, :aln_to, :hmm_from, :hmm_to
		attr_accessor :env_from, :env_to, :query_length, :seq_eval, :seq_score, :eval
		
		def initialize(id)
			super
		end

		# Checks whether the Domain hit is complete compared to the query length. By default checks for
		# full completeness (cutoff = 1) but this can be changed.
		def complete?(cut = 1)			
			completeness >= cut
		end
		
		# Computes the completeness, i.e. the ration between the number of residues matching
		# the domain and the length of the domain.
		def completeness
			# TODO: may be better to do this by referencing the parent class?
			l = hmm_to - hmm_from + 1
			l.to_f/query_length.to_f
		end
		
		def debug
			warn "+ DomainHit +"
			warn "* id: " + id.to_s
			warn "* ceval: " + ceval.to_s
			warn "* ieval: " + ieval.to_s
			warn "* score: " + score.to_s
			warn "* bias: " + bias.to_s
			warn "* aln_from: " + aln_from.to_s
			warn "* aln_to: " + aln_to.to_s
		end
	end

	# Class: SubHit
	# Purpose: Store information about sequence matches to different strand/frame
	# Date: 6/1/2010
	class SequenceHit < Item
		attr_accessor :score, :eval, :bias, :type, :desc, :target_name, :target_acc, :target_length, :query_name, :query_acc, :query_length, :strand, :frame
		def initialize(id)
			super
		end
		
		def each_domain
			each_value do |value|
				yield value
			end
		end

		# Returns a string with the localization in the sequence of the different domains in the SubHit.
		def localization
			loc = []
			# we have to sort the hash in this case.
			items.sort.each_index do |index|
				loc << items[index+1].aln_from.to_s + ".." + items[index+1].aln_to.to_s
			end
			loc.join(",")
		end

		# Checks whether there is any Domain <b>not complete</b> (fragment) in the Hit.
		def has_fragment?(cut = 1)
			each_domain do |domain|
				return true if domain.has_complete?(cut)
			end
			return false
		end

		# Checks whether there is any Domain <b>complete</b> in the Hit. See #complete?.
		def has_complete?(cut = 1)
			each_domain do |domain|
				return true if domain.has_complete?(cut)
			end
			return false
		end
		
		# Obtains the maximum completeness found in any of the Domains within the SubHit.
		def max_completeness
			mc = 0
			each_domain do |domain|
				smc = domain.completeness
				mc = smc if smc > mc
			end
			mc
		end
		
		# Obtains the minimum completeness found in any of the Domains within the SubHit.
		def min_completeness
			mc = 1
			each_domain do |domain|
				smc = domain.completeness
				mc = smc if smc < mc
			end
			mc
		end
		
		def debug
			warn "+ SubHit +"
			warn "* id: " + id
			warn "* eval: " + eval.to_s
			warn "* score: " + score.to_s
			warn "* frame: " + frame.to_s
			warn "* strand: " + strand.to_s
		end
	end
	
	# Sequence is a container class. It stores sequence-wise hits. For protein searches the
	# number of hits and subhits will be the same. But for nucleotide searches one hit may
	# contain several subhits. For a merge result, subhits may contain a mix of protein and
	# nucleotide results in the same sequence hit.
	class Sequence < Item
		attr_accessor :taxon, :ortholog
		
		def initialize(id)
			super
		end
		
		def each_sequencehit
			each_value do |value|
				yield value
			end
		end
		
		def eval
			best_subhit.eval
		end
		
		def score
			best_subhit.score
		end
		
		# Finds the best SubHit in a Hit.
		def best_subhit
			# If there is a "protein" SubHit that will be the best one. This assumes that only
			# one protein SubHit will be present. This may change in the future.
			hp = has_protein?
			csh = nil
			cbe = nil
			each_subhit do |subhit|
				return subhit if hp and subhit.type == "protein"
				if cbe.nil? or subhit.eval < cbe
					csh = subhit
					cbe = subhit.eval
				end
			end
			return csh
		end
		
		# Checks whether a hit contains a SubHit of type "nucleotide"
		def has_nucleotide?
			each_subhit do |subhit|
				#return true if subhit.type == "nucleotide"
				return true if subhit.type == "6frame"
			end
			return false
		end
		
		def has_protein?
			each_subhit do |subhit|
				return true if subhit.type == "protein"
			end
			return false
		end
		
		# A Hit is coherent if all of the SubHit are coherent.
		def coherent?
			return true if ! has_nucleotide?
			
			s = []
			p = []
			
			each_subhit do |subhit|
				if subhit.type == "nucleotide"
					s << subhit.strand
					p << subhit.frame
				end
			end
			p.uniq.length == 1 and s.uniq.length == 1
		end
		
		# A Hit has_fragment if any of the SubHit has_fragment.
		def has_fragment?(cut = 1)
			each_subhit do |subhit|
				return true if subhit.has_fragment?(cut)
			end
			return false
		end
		
		# A Hit has_complete if any of the SubHit has_complete.
		def has_complete?(cut = 1)
			each_subhit do |subhit|
				return true if subhit.has_complete?(cut)
			end
			return false
		end
		
		# Obtains the maximum completeness found in any of the SubHits within the Hit.
		def max_completeness
			mc = 0
			each_subhit do |subhit|
				smc = subhit.max_completeness
				mc = smc if smc > mc
			end
			mc
		end

		# Obtains the minimum completeness found in any of the SubHits within the Hit.
		def min_completeness
			mc = 1
			each_subhit do |subhit|
				smc = subhit.min_completeness
				mc = smc if smc < mc
			end
			mc
		end
		
		def debug
			warn "+ HIT +"
			warn "* id: " + id
			warn "* score: " + score.to_s
			warn "* e-value: " + eval.to_s
			warn "* has_complete?: " + has_complete?.to_s
			warn "* has_fragment?: " + has_fragment?.to_s
#			warn "* coherent?: " + coherent?.to_s
			warn "* taxon: " + taxon.name if ! taxon.nil?
			warn "* ortholog: " + ortholog.name if ! ortholog.nil?
		end
	end

	class Result < Item
		attr_accessor :taxon, :ortholog, :type, :tool
		attr_reader :config

		def initialize(id, options = {:config => nil})
			super(id)

			if options[:config]
				@config = options[:config]
			else
				@config = Config::General.new
			end
		end
		
		# Is this necessary?
		def <<(hit)
			add(hit)
		end
		
		# Overload the method to assign automatically taxon and ortholog to the hits.
		def add(hit)
			super
			hit.taxon = taxon
			hit.ortholog = ortholog
		end
		
		# Simple access method for each hit.
		def each_sequence
			each_value do |value|
				yield value
			end
		end

		# Removes subhits on the basis of an E-value cutoff (>). If no subhits remain the it
		# removes the hit from the result.
		def filter_by_eval(val)
			each_hit do |hit|
				hit.items.delete_if do |key, subhit|
					subhit.eval > val
				end
			end
			
			items.delete_if do |key, hit|
				hit.length == 0
			end
		end

		# Removes subhits on the basis of an Score cutoff (<). If no subhits remain the it
		# removes the hit from the result.
		def filter_by_score(val)
			each_hit do |hit|
				hit.items.delete_if do |key, subhit|
					subhit.score < val
				end
			end
			
			items.delete_if do |key, hit|
				hit.length == 0
			end
		end
		
		# Find the best Hit in a Result (maybe to create a PSI-Blast model).
		def best_hit
			ch = nil
			cbe = nil

			each_hit do |hit|
				if cbe.nil? or hit.eval < cbe
					ch = hit
					cbe = hit.eval
				end
			end
			return ch
		end
		
		def write_nelson
			case taxon.type
			when 'spp'
				write_nelson_spp
			when 'clade'
				write_nelson_clade
			end
		end
		
		def write_nelson_clade
			idb = Isolate::Set.new(taxon, options = {:config => config})
			
			# sets the family name (default == to the ortholog family name)
			fn = ortholog.name
			fs = Family::Set.new(options = {:config => config})
			family = fs.get_item_by_id(taxon.binomial + "-" + ortholog.name)
			if family
				fn = family.name
			end
			
			ofile = config.dir_result + "isolate/sequence" + ortholog.name + (id + ".txt")
			of = File.new(ofile, "w")
			of.puts	"SEQUENCE\t" +
				"accession\t" +
				"family\t" +
				"genome\t" +
				"taxid\t" +
				"source\t" +
				"locus\t" +
				"sequence\t" +
				"cds\t" + 
				"translation\t" +
				"pseudogene\t" +
				"method\t" +
				"score\t" +
				"evalue\t" +
				"hmmloc\t" +
				"description"
			each_hit do |hit|
				iseq = idb.get_seq_by_acc(hit.id)
				bh = hit.best_subhit
				
				pseudo = "FALSE"
				pseudo = "TRUE" if iseq.pseudogene == 1
				
				of.puts iseq.id + "\t" +
					iseq.accession + "\t" +
					taxon.binomial + "." + fn + "\t" +
					taxon.binomial + "." + taxon.id + "\t" +
					taxon.id + "\t" +
					iseq.source + "\t" +
					iseq.locus + "\t" +
					iseq.gene + "\t" +
					iseq.cds + "\t" +
					iseq.translation + "\t" +
					pseudo + "\t" +
					"psitblastn" + "\t" +
					bh.score.to_s + "\t" +
					bh.eval.to_s + "\t" +
					bh.localization + "\t" +
					iseq.description
			end
			of.close
		end
		
		# Export results in a format suitable to load in varDB (Nelson's preferred format)
		def write_nelson_spp
			gdb = Genome::Set.new(taxon, options = {:config => config})
			
			# sets the family name (default == to the ortholog family name)
			fn = ortholog.name
			fs = Family::Set.new(options = {:config => config})
			family = fs.get_item_by_id(taxon.binomial + "-" + ortholog.name)
			if family
				fn = family.name
			end

			ofile = config.dir_result + "genome/sequence" + ortholog.name + (id + ".txt")
			of = File.new(ofile, "w")
			of.puts	"SEQUENCE\t" +
				"family\t" +
				"genome\t" +
				"strain\t" +
				"taxid\t" +
				"source\t" + 
				"chromosome\t" +
				"sequence\t" +
				"cds\t" +
				"translation\t" +
				"start\t" +
				"end\t" +
				"strand\t" +
				"numexons\t" +
				"splicing\t" +
				"pseudogene\t" +
				"method\t" +
				"model\t" +
				"score\t" +
				"evalue\t" +
				"hmmloc\t" +
				"description"
			each_hit do |hit|
				g = gdb.get_gene_by_acc(hit.id)
				
				bh = hit.best_subhit
				pseudo = "FALSE"
				pseudo = "TRUE" if g.pseudogene == 1

				# FIX?: I am not including where the best hit is located (protein, gene, etc)
				# bh.type + "\t" +  # TODO: update to take care of new class SubHit
				of.puts hit.id + "\t" +
				taxon.binomial + "." + fn + "\t" +
				taxon.binomial + "." + taxon.id + "\t" +
				taxon.strain + "\t" +
				taxon.id + "\t" +
				taxon.source + "\t" +
				g.chromosome + "\t" +
				g.gene + "\t" +
				g.cds + "\t" +
				g.translation + "\t" +
				g.from.to_s + "\t" +
				g.to.to_s + "\t" +
				g.strand.to_s + "\t" +
				g.length.to_s + "\t" +
				g.splicing_nelson + "\t" +
				pseudo + "\t" +
				"hmmsearch" + "\t" +
				ortholog.hmm + "\t" +
				bh.score.to_s + "\t" +
				bh.eval.to_s + "\t" +
				bh.localization + "\t" +
				g.description
			end
			of.close
		end

		# This method will write the FASTA sequences.
		def write_fasta
			case taxon.type
			when 'spp'
				write_fasta_spp
			when 'clade'
				write_fasta_clade
			end
		end
		
		def write_fasta_spp
			genome = Genome::Set.new(taxon, options = {:config => config})
			genome.filter_by_acc(items.keys)
			["protein", "cds", "gene"].each do |type|
				file = config.dir_result + "genome/fasta" + ortholog.name + (id + "_" + type + ".fa")
				genome.write_fasta(type, file)
			end
		end
		
		def write_fasta_clade
			isolate = Isolate::Set.new(taxon, options = {:config => config})
			isolate.filter_by_acc(items.keys)
			["protein", "cds", "gene"].each do |type|
				file = config.dir_result + "isolate/fasta" + ortholog.name + (id + "_" + type + ".fa")
				isolate.write_fasta(type, file)
			end
		end
		
		def debug
			warn "+ RESULT +"
			warn "* result id: " + id
			warn "* tool: " + tool
			warn "* hits: " + length.to_s
			nsh = 0
			ndom = 0
			each_value do |hit|
				#warn "* hit id: " + hit.id
				nsh += hit.length
				hit.items.each_value do |subhit|
					#warn "* subhit id: " + subhit.id
					ndom += subhit.length
				end
			end
			warn "* subhits: " + nsh.to_s
			warn "* domains: " + ndom.to_s
		end
	end

	class Set < Set
		def initialize(options = {:config => nil})
			super()
			
			if options[:config]
				@config = options[:config]
			else
				@config = Config::General.new
			end
		end
		
		def each_result
			each_value do |value|
				yield value
			end
		end
		
		# Finds the best hit in all the Results.
		# TODO: have an eye on this limit thing. currently not used. in update_pssm we filter first the
		# results based on type, so only protein results are included in the set.
		def best_hit(limit = nil)
			bh = nil
			items.each_value do |result|
				if ! limit.nil?
					next if ! limit.include?(result.type)
				end
				ch = result.best_hit
				bh = ch if bh.nil? or ch.eval < bh.eval
			end
			return bh
		end
		
		def auto_merge
			rs = Set.new
			each_result do |result|
				id = result.taxon.name + "-" + result.ortholog.name
				r = rs.get_item_by_id(id)
				if r.nil?
					r = Result.new(id, options = {:config => result.config})
					r.taxon = result.taxon
					r.ortholog = result.ortholog
					r.type = result.type
					rs << r
				end

				result.each_value do |hit|
					h = r.get_item_by_id(hit.id)
					if h.nil?
						h = Sequence.new(hit.id)
						r << h
					end

					hit.each_value do |subhit|
						h << subhit
					end
				end
			end
			rs
		end
		
		# Removes Result instances in a Set if they not contain any hit.
		def clean_up
			items.delete_if do |key, result|
				result.length == 0
			end
		end
		
		# Produces a tabulated report.
		def report(cut = 1)
			puts "hit_name\tsearch_id\ttaxon\tortholog\tnsubhits\tndomains\tmin_completeness\tmax_completeness\tfragment\tcomplete\tcoherent\tbest_eval\tbest_score"
			each_value do |result|
				next if ! (result.length > 0)
				result.each_value do |hit|
					dl = 0
					hit.items.each_value do |subhit|
						dl += subhit.length
					end
					
					bsh = hit.best_subhit
					
					puts hit.id + "\t" + result.taxon.name + "." + result.ortholog.name + "\t" + result.taxon.name + "\t" + result.ortholog.name + "\t" + hit.length.to_s + "\t" + \
						dl.to_s + "\t" + "%.2f" % hit.min_completeness + "\t" + "%.2f" % hit.max_completeness + "\t" + \
						hit.has_fragment?(cut).to_s.upcase + "\t" + hit.has_complete?(cut).to_s.upcase + "\t" + hit.coherent?.to_s.upcase + "\t" + \
						bsh.eval.to_s + "\t" + bsh.score.to_s
				end
			end
		end
		
		# Produces a tabulated summary.
		def report_summary
			puts "taxon\tortholog\tcount"
			each_value do |result|
				puts result.taxon.kegg_name + "\t" + result.ortholog.name + "\t" + result.length.to_s if result.length > 0
			end
		end

		# Exports data in format suitable for varDB (a.k.a. Nelson format).
		def write_nelson
			warn "+ WRITE NELSON +" 
			each_result do |result|
				if result.length > 0
					warn "* " + result.taxon.name + " / " + result.ortholog.name
					result.write_nelson
				end
			end
		end

		# Exports sequences in FASTA format.
		def write_fasta
			warn "+ WRITE FASTA +"
			each_value do |result|
				if result.length > 0
					warn "* " + result.taxon.name + " / " + result.ortholog.name
					result.write_fasta
				end
			end
		end

		#
		def filter_by_eval(cut = 0.001)
			each_value do |result|
				if result.length > 0
					result.filter_by_eval(cut)
				end
			end
		end

		def debug
			warn "+ RESULT SET +"
			warn "* results: " + length.to_s
			each_result do |result|
				result.debug
			end
		end
	end
	
	class BlastParser
		attr_reader :taxon, :ortholog
		attr_accessor :file, :result_id, :type, :config

		def initialize(options = {:config => nil, :taxon => nil, :ortholog => nil, :empty => false})
			if options[:config]
				@config = options[:config]
			else
				@config = Config::General.new
			end
			
			
			@taxon = options[:taxon] if options[:taxon]
			@ortholog = options[:ortholog] if options[:ortholog]

			@file = nil
			@result_id = nil
			@type = nil
		end
		
		def parse
			result = Result.new(result_id, options = {:config => config})
			result.taxon = taxon if taxon
			result.ortholog = ortholog if ortholog
			result.type = type if type
			
			fi = File.open(file)
			fi.each do |line|
				next if line =~ /^#/
				line.chomp
				qid, tid, piden, alen, mis, gaps, qs, qe, ts, te, eval, score, sframe = line.split("\t")
				h = result.get_item_by_id(tid)
				if h.nil?
					h = Sequence.new(tid)
					result << h
				end
			
				sp = sframe.split(/./)
				sid = tid
				#warn "* subhit id: " + sid
				sh = h.get_item_by_id(sid)
				if sh.nil?
					sh = SequenceHit.new(sid)
					sh.score = score.to_f
					sh.eval = eval.to_f
					sh.target_name = tid
					#sh.target_acc = tacc
					#sh.target_length = tlen.to_i
					sh.query_name = qid
					#sh.query_acc = qacc
					sh.query_length = (qe.to_i - qs.to_i + 1).to_s
					sh.type = type
					sh.strand = sp[0]
					sh.frame = sp[1]
					h << sh
				end
				dom = Domain.new(sh.length + 1)
				dom.hmm_from = qs.to_i
				dom.hmm_to = qe.to_i
				dom.aln_from = ts.to_i
				dom.aln_to = te.to_i
				#dom.env_from = ef.to_i
				#dom.env_to = et.to_i
				#dom.ceval = dceval
				#dom.ieval = dieval
				dom.eval = eval
				dom.score = score
				#dom.bias = dbias
				# TODO: may be better to do this by referencing the parent class?
				#dom.query_length = qlen.to_i
				sh.add(dom)
			end
			fi.close
			
			result
		end
	end
	
	class HmmscanParser
		attr_reader :taxon, :ortholog
		attr_accessor :file, :result_id, :type, :config

		def initialize(options = {:config => nil, :taxon => nil, :ortholog => nil, :empty => false})
			if options[:config]
				@config = options[:config]
			else
				@config = Config::General.new
			end
			
			
			@taxon = options[:taxon] if options[:taxon]
			@ortholog = options[:ortholog] if options[:ortholog]
			
			@file = nil
			@result_id = nil
			@type = nil
		end
		
		def parse
			result = Result.new(result_id, options = {:config => config})
			result.taxon = taxon if taxon
			result.ortholog = ortholog if ortholog
			
			result
		end
	end

	class HmmerParser
		attr_reader :taxon, :ortholog, :tool
		attr_accessor :file, :result_id, :type, :config
		
		def initialize(options = {:config => nil, :taxon => nil, :ortholog => nil, :empty => false, :tool => nil})
			if options[:config]
				@config = options[:config]
			else
				@config = Config::General.new
			end
			
			
			@taxon = options[:taxon] if options[:taxon]
			@ortholog = options[:ortholog] if options[:ortholog]
			@tool = options[:tool]
			
			@file = nil
			@result_id = nil
			@type = nil
		end
		
		def parse
			result = Result.new(result_id, options = {:config => config})
			result.taxon = taxon if taxon
			result.ortholog = ortholog if ortholog
			result.tool = tool
			
			fi = File.open(file)
			fi.each do |line|
				next if line =~ /^#/
				line.chomp
				tid, tacc, tlen, qid, qacc, qlen, seval, sscore,
				sbias, dn, dtot, dceval, dieval, dscore, dbias, hf, ht,
				af, at, ef, et, acc = line.split(' ')
				
				case tool
				when 'hmmsearch'
					h = result.get_item_by_id(tid)
					if h.nil?
						h = Sequence.new(tid)
						result.add(h)
					end
				
					sp = []	
					#if type == "nucleotide"
					if type == "6frame"
						sp = _parse_line(line)
						if sp.nil?
							raise "ERROR: nucleotide result does not contain strand/frame information"
						else
							sid = tid + "[" + sp[0] + "|" + sp[1] + "]"
						end
					else
						sid = tid
					end
					#warn "* subhit id: " + sid
					sh = h.get_item_by_id(sid)
					if sh.nil?
						sh = SequenceHit.new(sid)
						sh.score = sscore.to_f
						sh.eval = seval.to_f
						sh.target_name = tid
						sh.target_acc = tacc
						sh.target_length = tlen.to_i
						sh.query_name = qid
						sh.query_acc = qacc
						sh.query_length = qlen.to_i
						sh.type = type
						sh.strand = sp[0]
						sh.frame = sp[1]
						h << sh
					end
					dom = Domain.new(sh.length + 1)
					dom.hmm_from = hf.to_i
					dom.hmm_to = ht.to_i
					dom.aln_from = af.to_i
					dom.aln_to = at.to_i
					dom.env_from = ef.to_i
					dom.env_to = et.to_i
					dom.ceval = dceval
					dom.ieval = dieval
					dom.score = dscore
					dom.bias = dbias
					# TODO: may be better to do this by referencing the parent class?
					dom.query_length = qlen.to_i
					sh.add(dom)
				when 'hmmscan'
					h = result.get_item_by_id(qid)
					if h.nil?
						h = Sequence.new(qid)
						result.add(h)
					end
					
					sh = h.get_item_by_id(qid)
					if sh.nil?
						sh = SequenceHit.new(qid)
						h << sh
					end
					
					dom = sh.get_item_by_id(tid)
					if dom.nil?
						dom = Domain.new(tid)
						dom.eval = seval.to_f
						dom.score = sscore.to_f
						dom.bias = sbias.to_f
						sh << dom
					end
					
					dh = DomainHit.new(dom.length + 1)
					dh.hmm_from = hf.to_i
					dh.hmm_to = ht.to_i
					dh.aln_from = af.to_i
					dh.aln_to = at.to_i
					dh.env_from = ef.to_i
					dh.env_to = et.to_i
					dh.ceval = dceval
					dh.ieval = dieval
					dh.score = dscore
					dh.bias = dbias
					# TODO: may be better to do this by referencing the parent class?
					dh.query_length = tlen.to_i
					dom << dh
				end
			end
			fi.close
			
			result
		end
		
		# Prints some information for debugging.
		def debug
			warn "+ HmmerParser +"
			warn "* file: " + @file
			result.debug
		end
		
		private
		
		def _parse_line(line)
			tmp = line.match(/\[(.+)\]$/)
			if ! tmp.nil?
				tmp = tmp[0]
				tmp.gsub!(/\[|\]/, "")
				strand, frame = tmp.split(';')
				strand.sub!(/strand=/, "")
				frame.sub!(/frame=/, "")

				#warn "* strand: " + strand
				#warn "* frame: " + frame
				
				return [strand, frame]
			end
			return nil
		end
	end
end
