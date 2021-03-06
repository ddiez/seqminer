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
require 'common'

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
			warn "+ Result::Sequence::SequenceHit::Domain +"
			warn "* id: " + id.to_s
			warn "* length: " + length.to_s
			warn "* eval: " + eval.to_s
			warn "* score: " + score.to_s
			warn "* bias: " + bias.to_s
		end
	end

	class DomainHit < Item
		attr_accessor :ceval, :ieval, :score, :bias, :aln_from, :aln_to, :hmm_from, :hmm_to
		attr_accessor :env_from, :env_to, :domain_length, :seq_eval, :seq_score, :eval
		
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
			l = match_length
			l.to_f/domain_length.to_f
		end
		
		def match_length
			hmm_to - hmm_from + 1
		end
		
		def debug
			warn "+ Result::Sequence::SequenceHit::Domain::DomainHit +"
			warn "* id: " + id.to_s
			warn "* ceval: " + ceval.to_s
			warn "* ieval: " + ieval.to_s
			warn "* score: " + score.to_s
			warn "* bias: " + bias.to_s
			warn "* aln_from: " + aln_from.to_s
			warn "* aln_to: " + aln_to.to_s
			warn "* domain length: " + domain_length.to_s
			warn "* match length: " + match_length.to_s
			warn "* completeness: " + completeness.to_s
		end
	end

	# Class: SubHit
	# Purpose: Store information about sequence matches to different strand/frame
	# Date: 6/1/2010
	class SequenceHit < Item
		attr_accessor :score, :eval, :bias, :type, :desc, :target_name, :target_acc, :target_length, :query_name, :query_acc, :domain_length, :strand, :frame
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
#			items.sort.each_index do |index|
#				loc << items[index+1].aln_from.to_s + ".." + items[index+1].aln_to.to_s
#			end
#			loc.join(",")
			each_domain do |domain|
				domain.each_domainhit do |dh|
					loc << dh.aln_from.to_s + ".." + dh.aln_to.to_s
				end
			end
			loc.join(",")
		end

		# Checks whether there is any Domain <b>not complete</b> (fragment) in the Hit.
		def has_fragment?(cut = 1)
			each_domain do |domain|
				return true if domain.has_fragment?(cut)
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
			warn "+ Result::Sequence::SequenceHit +"
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
			each_sequencehit do |subhit|
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
			each_sequencehit do |subhit|
				#return true if subhit.type == "nucleotide"
				return true if subhit.type == "6frame"
			end
			return false
		end
		
		def has_protein?
			each_sequencehit do |subhit|
				return true if subhit.type == "protein"
			end
			return false
		end
		
		# A Hit is coherent if all of the SubHit are coherent.
		def coherent?
			return true if ! has_nucleotide?
			
			s = []
			p = []
			
			each_sequencehit do |subhit|
				if subhit.type == "nucleotide"
					s << subhit.strand
					p << subhit.frame
				end
			end
			p.uniq.length == 1 and s.uniq.length == 1
		end
		
		# A Hit has_fragment if any of the SubHit has_fragment.
		def has_fragment?(cut = 1)
			each_sequencehit do |sh|
				return true if sh.has_fragment?(cut)
			end
			return false
		end
		
		# A Hit has_complete if any of the SubHit has_complete.
		def has_complete?(cut = 1)
			each_sequencehit do |subhit|
				return true if subhit.has_complete?(cut)
			end
			return false
		end
		
		# Obtains the maximum completeness found in any of the SubHits within the Hit.
		def max_completeness
			mc = 0
			each_sequencehit do |subhit|
				smc = subhit.max_completeness
				mc = smc if smc > mc
			end
			mc
		end

		# Obtains the minimum completeness found in any of the SubHits within the Hit.
		def min_completeness
			mc = 1
			each_sequencehit do |subhit|
				smc = subhit.min_completeness
				mc = smc if smc < mc
			end
			mc
		end
		
		def debug
			warn "+ Result::Sequence +"
			warn "* id: " + id
			warn "* score: " + score.to_s
			warn "* e-value: " + eval.to_s
			warn "* has_complete?: " + has_complete?.to_s
			warn "* has_fragment?: " + has_fragment?.to_s
			warn "* coherent?: " + coherent?.to_s
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
			dh = []
			each_sequence do |hit|
				dsh = []
				hit.each_sequencehit do |sh|
					dsh << sh if sh.eval > val
				end
				dsh.each do |i|
					hit.delete(i)
				end
				dh << hit if hit.length == 0
			end
			dh.each do |i|
				delete(i)
			end
		end
		
		def filter_domain_by_eval(val = 0.001)
			each_sequence do |seq|
				seq.each_sequencehit do |sh|
					dd = []
					sh.each_domain do |domain|
						dd << domain if domain.eval > val
					end
					dd.each do |i|
						sh.delete(i)
					end
					seq.delete(sh) if sh.length == 0
				end
				delete(seq) if seq.length == 0
			end
		end

		# Removes subhits on the basis of an Score cutoff (<). If no subhits remain the it
		# removes the hit from the result.
		def filter_by_score(val)
			dh = []
			each_sequence do |hit|
				dsh = []
				hit.each_sequencehit do |sh|
					dsh << sh if sh.score < val
				end
				dsh.each do |i|
					hit.delete(i)
				end
				dh << hit if hit.length == 0
			end	
			dh.each do |i|
				delete(i)
			end
		end
		
		# Find the best Hit in a Result (maybe to create a PSI-Blast model).
		def best_hit
			ch = nil
			cbe = nil

			each_sequence do |hit|
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
			each_sequence do |hit|
				iseq = idb.get_seq_by_acc(hit.id)
				bh = hit.best_subhit
				
				pseudo = "FALSE"
				pseudo = "TRUE" if iseq.pseudogene == 1
				
				# TODO: there are incoherences in the current implementation between isolate
				# and gene sequences in terms of translation.
				if iseq.translation.nil?
					transl = ""
				else
					transl = iseq.translation
				end
				
				of.puts iseq.id + "\t" +
					iseq.accession + "\t" +
					taxon.binomial + "." + fn + "\t" +
					taxon.binomial + "." + taxon.id + "\t" +
					taxon.id + "\t" +
					iseq.source + "\t" +
					iseq.locus + "\t" +
					iseq.gene + "\t" +
					iseq.cds + "\t" +
					transl + "\t" +
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
			each_sequence do |hit|
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
		
		def write_domain(file = nil)
			case taxon.type
			when 'spp'
				file = config.dir_result + "genome/domain" + ortholog.name + (id + ".txt")
			when 'clade'
				file = config.dir_result + "isolate/domain" + ortholog.name + (id + ".txt")
			end
			fo = File.new(file, "w")
			fo.puts "SEQUENCE\tdomainnum\ttotaldomainnum\tdomains"
			each_sequence do |seq|
				doms = []
				domsn = 0
				dhn = 0
				loc = []
				seq.each_sequencehit do |sh|
					sh.each_domain do |dom|
						#next if dom.eval > 0.01
						domc = dom.id + ":"
						domsn += 1
						tmp = []
						dom.each_domainhit do |dh|
							tmp << dh.aln_from.to_s + ".." + dh.aln_to.to_s + "[" + dh.score.to_s + "|" + dh.ieval.to_s + "]"
							dhn += 1
						end
						tmp = tmp.join(",")
						loc << "[" + tmp + "]"
						doms << domc + tmp
					end
				end
				doms = doms.join(";")
				fo.puts seq.id + "\t" + domsn.to_s + "\t" + dhn.to_s + "\t" + doms
			end
			fo.close
		end
		
		def debug
			warn "+ Result +"
			warn "* result id: " + id
			warn "* tool: " + tool.to_s
			warn "* sequences: " + length.to_s
			nsh = 0
			ndom = 0
			ndomh = 0
			each_sequence do |hit|
				nsh += hit.length
				hit.each_sequencehit do |subhit|
					ndom += subhit.length
					subhit.each_domain do |domain|
						ndomh += domain.length
					end
				end
			end
			warn "* sequence hits: " + nsh.to_s
			warn "* domains: " + ndom.to_s
			warn "* domain hits: " + ndomh.to_s
		end
	end

	class Set < Set
		attr_reader :config
		def initialize(options = {:config => nil, :project => nil})
			super()
			
			if options[:config]
				@config = options[:config]
			else
				@config = Config::General.new(options[:project])
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
			rs = Set.new(options = {:config => config})
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
			dr = []
			each_result do |result|
				dr << result if result.length == 0
			end
			dr.each do |i|
				delete(i)
			end
		end
		
		# Produces a tabulated report.
		def report(cut = 1)
			f = File.open(config.dir_home + "report.txt", "w")
			f.puts "hit_name\tsearch_id\ttaxon\tortholog\tnsubhits\tndomains\tmin_completeness\tmax_completeness\tfragment\tcomplete\tcoherent\tbest_eval\tbest_score"
			each_value do |result|
				next if ! (result.length > 0)
				result.each_sequence do |hit|
					dl = 0
					hit.each_sequencehit do |subhit|
						dl += subhit.length
					end
					
					bsh = hit.best_subhit
					
					f.puts hit.id + "\t" + result.taxon.name + "." + result.ortholog.name + "\t" + result.taxon.name + "\t" + result.ortholog.name + "\t" + hit.length.to_s + "\t" + \
						dl.to_s + "\t" + "%.2f" % hit.min_completeness + "\t" + "%.2f" % hit.max_completeness + "\t" + \
						hit.has_fragment?(cut).to_s.upcase + "\t" + hit.has_complete?(cut).to_s.upcase + "\t" + hit.coherent?.to_s.upcase + "\t" + \
						bsh.eval.to_s + "\t" + bsh.score.to_s
				end
			end
			f.close
		end
		
		# Produces a tabulated summary.
		def report_summary
			f = File.open(config.dir_home + "summary.txt", "w")
			f.puts "taxon\tortholog\tcount"
			each_value do |result|
				f.puts result.taxon.kegg_name + "\t" + result.ortholog.name + "\t" + result.length.to_s if result.length > 0
			end
			f.close
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

		# Exports domain data in format suitable for varDB (a.k.a. Nelson format).
		def write_domain
			warn "+ WRITE DOMAIN +"
			each_result do |result|
				if result.length > 0
					warn "* " + result.taxon.name + " / " + result.ortholog.name
					result.write_domain
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
		
		def filter_domain_by_eval(cut = 0.001)
			each_result do |result|
				result.filter_domain_by_eval(cut)
			end
		end

		def debug
			warn "+ Result Set +"
			warn "* results: " + length.to_s
			each_result do |result|
				result.debug
			end
		end
	end
	
	class BlastParser
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
			result.type = type if type
			result.tool = tool
			
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
					sh.domain_length = (qe.to_i - qs.to_i + 1).to_s
					sh.type = type
					sh.strand = sp[0]
					sh.frame = sp[1]
					h << sh
				end

				dom = sh.get_item_by_id(qid)
				if dom.nil?
					dom = Domain.new(qid)
#					dom.eval = eval.to_f
#					dom.score = score.to_f
#					dom.bias = sbias.to_f
					sh << dom
				end
				
				dh = DomainHit.new(dom.length + 1)
				#dom = Domain.new(sh.length + 1)
				dh.hmm_from = qs.to_i
				dh.hmm_to = qe.to_i
				dh.aln_from = ts.to_i
				dh.aln_to = te.to_i
				#dh.env_from = ef.to_i
				#dh.env_to = et.to_i
				#dh.ceval = dceval
				#dh.ieval = dieval
				dh.eval = eval
				dh.score = score
				#dh.bias = dbias
				# TODO: may be better to do this by referencing the parent class?
				#dh.domain_length = qlen.to_i
				dom << dh
			end
			fi.close
			
			result
		end
	end
	
	class HmmerParser
		attr_reader :taxon, :ortholog, :tool, :result
		attr_accessor :file, :result_id, :type, :config
		
		def initialize(options = {:config => nil, :taxon => nil, :ortholog => nil, :empty => false, :tool => nil, :project => nil})
			if options[:config]
				@config = options[:config]
			else
				@config = Config::General.new(options[:project])
			end
			
			
			@taxon = options[:taxon] if options[:taxon]
			@ortholog = options[:ortholog] if options[:ortholog]
			@tool = options[:tool]
			
			@file = nil
			@result_id = nil
			@type = nil
		end
		
		def parse
			@result = Result.new(result_id, options = {:config => config})
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
						sh.domain_length = qlen.to_i
						sh.type = type
						sh.strand = sp[0]
						sh.frame = sp[1]
						h << sh
					end
					
					dom = sh.get_item_by_id(qid)
					if dom.nil?
						dom = Domain.new(qid)
						#dom.eval = seval.to_f
						#dom.score = sscore.to_f
						#dom.bias = sbias.to_f
						sh << dom
					end
					
					dh = DomainHit.new(dom.length + 1)
					#dom = Domain.new(sh.length + 1)
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
					dh.domain_length = qlen.to_i
					dom << dh
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
					dh.domain_length = tlen.to_i
					dom << dh
				end
			end
			fi.close
			
			result
		end
		
		# Prints some information for debugging.
		def debug
			warn "+ HmmerParser +"
			warn "* file: " + @file.to_s
			result.debug if ! result.nil?
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
