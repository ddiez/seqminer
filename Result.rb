require 'SeqMiner'
require 'Item'
require 'Genome'
require 'Sequence'

module Result
	include Item
	class Domain < Item
		attr_accessor :ceval, :ieval, :score, :bias, :aln_from, :aln_to, :hmm_from, :hmm_to, :env_from, :env_to, :query_length, :seq_eval, :seq_score
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
	end

	# Class: SubHit
	# Purpose: Store information about sequence matches to different strand/frame
	# Date: 6/1/2010
	class SubHit < Item
		attr_accessor :score, :eval, :type, :desc, :target_name, :target_acc, :target_length, :query_name, :query_acc, :query_length, :strand, :frame
		def initialize(id)
			super
		end

		# Returnsa string with the localization in the sequence of the different domains in the SubHit.
		def localization
			loc = []
			# we have to sort the hash in this case.
			@items.sort.each_index do |index|
				loc << @items[index+1].aln_from.to_s + ".." + @items[index+1].aln_to.to_s
			end
			loc.join(",")
		end

		# Checks whether there is any Domain <b>not complete</b> (fragment) in the Hit.
		def has_fragment?(cut = 1)
			each_value do |domain|
				return true if ! domain.complete?(cut)
			end
			return false
		end

		# Checks whether there is any Domain <b>complete</b> in the Hit. See #complete?.
		def has_complete?(cut = 1)
			each_value do |domain|
				return true if domain.complete?(cut)
			end
			return false
		end
		
		# Obtains the maximum completeness found in any of the Domains within the SubHit.
		def max_completeness
			mc = 0
			each_value do |domain|
				smc = domain.completeness
				mc = smc if smc > mc
			end
			mc
		end
		
		# Obtains the minimum completeness found in any of the Domains within the SubHit.
		def min_completeness
			mc = 1
			each_value do |domain|
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
	
	# Hit is a container class. It stores sequence-wise hits. For protein searches the
	# number of hits and subhits will be the same. But for nucleotide searches one hit may
	# contain several subhits. For a merge result, subhits may contain a mix of protein and
	# nucleotide results in the same sequence hit.
	class Hit < Item
		def initialize(id)
			super
		end
		
		# Finds the best SubHit in a Hit.
		def best_subhit
			# If there is a "protein" SubHit that will be the best one. This assumes that only
			# one protein SubHit will be present. This may change in the future.
			hp = has_protein?
			csh = nil
			cbe = nil
			each_value do |subhit|
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
			each_value do |subhit|
				#return true if subhit.type == "nucleotide"
				return true if subhit.type == "6frame"
			end
			return false
		end
		
		def has_protein?
			each_value do |subhit|
				return true if subhit.type == "protein"
			end
			return false
		end
		
		# A Hit is coherent if all of the SubHit are coherent.
		def coherent?
			return true if ! has_nucleotide?
			
			s = []
			p = []
			
			each_value do |subhit|
				if subhit.type == "nucleotide"
					s << subhit.strand
					p << subhit.frame
				end
			end

			p.uniq.length == 1 and s.uniq.length == 1
		end
		
		# A Hit has_fragment if any of the SubHit has_fragment.
		def has_fragment?(cut = 1)
			each_value do |subhit|
				return true if subhit.has_fragment?(cut)
			end
			return false
		end
		
		# A Hit has_complete if any of the SubHit has_complete.
		def has_complete?(cut = 1)
			each_value do |subhit|
				return true if subhit.has_complete?(cut)
			end
			return false
		end
		
		# Obtains the maximum completeness found in any of the SubHits within the Hit.
		def max_completeness
			mc = 0
			each_value do |subhit|
				smc = subhit.max_completeness
				mc = smc if smc > mc
			end
			mc
		end

		# Obtains the minimum completeness found in any of the SubHits within the Hit.
		def min_completeness
			mc = 1
			each_value do |subhit|
				smc = subhit.min_completeness
				mc = smc if smc < mc
			end
			mc
		end
	end

	class Result < Item
		attr_accessor :taxon, :ortholog, :type
		attr_reader :config

		def initialize(id, options = {:config => nil})
			super(id)

			if ! options[:config]
				@config = SeqMiner::Config.new
			else
				@config = options[:config]
			end
		end

		# Removes subhits on the basis of an E-value cutoff (>). If no subhits remain the it
		# removes the hit from the result.
		def filter_by_eval(val)
			each_value do |hit|
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
			each_value do |hit|
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
			# TODO: Implement.
#			items.each_value do |hit|
#				
#			end
		end

		# Export results in a format suitable to load in varDB (Nelson's preferred format)
		def export_nelson
			ndb = Sequence::Set.new(taxon.name, "gene")
			pdb = Sequence::Set.new(taxon.name, "protein")
			gdb = Genome::Set.new(taxon)

			ofile = config.dir_result + "genome/sequences" + ortholog.name + (id + ".txt")
			of = File.new(ofile, "w")
			each_value do |hit|
				ns = ndb.get_seq_by_acc(hit.id)
				ps = pdb.get_seq_by_acc(hit.id)
				g = gdb.get_gene_by_acc(hit.id)
				
				bh = hit.best_subhit

				if ns.nil?
					nseq = ""
				else
					nseq = ns.seq
				end

				if ps.nil?
					pseq = ""
				else
					pseq = ps.seq
				end

				of.puts hit.id + "\t" +
				taxon.binomial + "." + ortholog.name + "\t" +
				taxon.binomial + "." + taxon.id + "\t" +
				taxon.strain + "\t" +
				taxon.id + "\t" +
				taxon.source + "\t" +
				g.chromosome + "\t" +
				pseq + "\t" +
				nseq + "\t" +
				g.from.to_s + "\t" +
				g.to.to_s + "\t" +
				g.strand.to_s + "\t" +
				g.length.to_s + "\t" + # this is number of exons- may change
				g.splicing + "\t" +
				ortholog.hmm + "\t" +
				bh.type + "\t" +  # TODO: update to take care of new class SubHit
				bh.score.to_s + "\t" +
				bh.eval.to_s + "\t" +
				bh.localization + "\t" +
				g.description
			end
			of.close
		end

		# This method will write the FASTA sequences.
		def write_fasta
			genome = Genome::Set.new(taxon, options = {:config => config})
			genome.filter_by_acc(items.keys)
			["protein", "cds", "gene"].each do |type|
				file = config.dir_result + "genome/fasta" + ortholog.name + (id + "_" + type + ".fa")
				genome.write_fasta(type, file)
			end
		end

		# Exports sequence information as FASTA format
		def export_fasta
			ndb = Sequence::Set.new(taxon.name, "gene")
			pdb = Sequence::Set.new(taxon.name, "protein")

			# TODO: have something like this:
			onfile = config.dir_result + "genome/fasta/" + ortholog.name + (id + "_nucleotide.fa")
			opfile = config.dir_result + "genome/fasta/" + ortholog.name + (id + "_protein.fa")
			onf = File.new(onfile, "w")
			opf = File.new(opfile, "w")
			each_value do |hit|
				ns = ndb.get_seq_by_acc(hit.id)
				ps = pdb.get_seq_by_acc(hit.id)

				if ! ns.nil?
					onf.puts ns.to_fasta(ns.definition)
				end

				if ! ps.nil?
					opf.puts ps.to_fasta(ps.definition)
				end
			end
			onf.close
			opf.close
		end

		def debug
			warn "+ RESULT +"
			warn "* result id: " + id
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
		def initialize
			super
		end

		def auto_merge
			rs = Set.new
			each_value do |result|
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
						h = Hit.new(hit.id)
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
		def export_nelson
			warn "+ EXPORT NELSON +" 
			each_value do |result|
				if result.length > 0
					warn "* " + result.taxon.name + " / " + result.ortholog.name
					result.export_nelson
				end
			end
		end

		# Exports sequences in FASTA format.
		def write_fasta
			each_value do |result|
				if result.length > 0
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
			items.each_value do |result|
				result.debug
			end
		end
	end

	class HmmerParser
		attr_accessor :file, :result_id, :type, :config
		
		# Check whether a valid type is assign to the Result object.
#		def is_valid?(type)
#			valid = ['nucleotide', 'protein']
#			valid.include?(type)
#		end
		
		def initialize
			@config = nil
		end
		
		
		def parse
			result = Result.new(result_id, options = {:config => config})
			
			fi = File.open(file)
			fi.each do |line|
				next if line =~ /^#/
				line.chomp
				tid, tacc, tlen, qid, qacc, qlen, seval, sscore,
				sbias, dn, dtot, dceval, dieval, dscore, dbias, hf, ht,
				af, at, ef, et, acc = line.split(' ')
				h = result.get_item_by_id(tid)
				if h.nil?
					h = Hit.new(tid)
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
					sh = SubHit.new(sid)
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
			end
			fi.close

			result
		end
		
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

		# Prints some information for debugging.
		def debug
			warn "+ HmmerParser +"
			warn "* file: " + @file
			result.debug
		end
	end
end
