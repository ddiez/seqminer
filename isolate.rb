require 'SeqMiner'
require 'Item'
require 'Sequence'

module Isolate
	include Item

	class Set < Set
		attr_reader :config, :name, :file
		
		def initialize(name, options = {:empty => false, :config => nil})
			super()
			
			if options[:config]
				@config = options[:config]
			else
				@config = SeqMiner::Config.new
			end
			
			if options[:empty]
				@file = "_undef_"
			else
			end
		end
		
		def each_isolate
			items.each_value do |value|
				yield value
			end
		end
		
		# Returns a sequence based on the accession value.
		def get_seq_by_acc(acc)
			get_item_by_id(acc)
		end
		
		# Returns a sequence in the Isolate::Set based on the subid value.
		def get_seq_by_subid(subid)
			each_value do |seq|
				return seq if seq.subid == subid
			end
			return nil
		end
		
		def auto_clean
			items.delete_if do |id, seq|
				seq.size < 3
			end
		end

		
		# Writes a FASTA file with sequences based on the different types: gene (3'->5' sequence), CDS (the coding
		# sequences; i.e. the reverse complement if necesary), protein (tranlated from the CDS) or 6frame (6 possible
		# translations based upon frame and strand).
		def write_fasta(type, file = nil)
			if file
				fo = File.new(file, "w")
			else
				fo = $stdout
			end
			
			case type
			when "gene"
				items.each_value do |seq|
					id = seq.id + " accession=" + seq.accession + ";source=" + seq.source + \
						";type=" + seq.type + ";description=" + seq.description + ";"
					fo.puts seq.sequence.to_fasta(id, 60)
				end
			when "cds"
				items.each_value do |seq|
					id = seq.id + " accession=" + seq.accession + ";source=" + seq.source + \
						";type=" + seq.type + ";description=" + seq.description + ";"
					fo.puts seq.cds.to_fasta(id, 60)
				end
			when "protein"
				items.each_value do |seq|
					next if ! seq.translation
					id = seq.id + " accession=" + seq.accession + ";source=" + seq.source + \
						";type=" + seq.type + ";trans_table=" + seq.trans_table.to_s + ";description=" + seq.description + ";"
					fo.puts seq.translation.to_fasta(id, 60)
				end
			when '6frame'
				items.each_value do |seq|
					id = seq.id + " accession=" + seq.accession + ";source=" + seq.source + \
						";type=" + seq.type + ";trans_table=" + seq.trans_table.to_s + ";description=" + seq.description + ";"
					fo.puts seq.translate(1).to_fasta(id + " [strand=#{seq.strand};frame=1]", 60)
					fo.puts seq.translate(2).to_fasta(id + " [strand=#{seq.strand};frame=2]", 60)
					fo.puts seq.translate(3).to_fasta(id + " [strand=#{seq.strand};frame=3]", 60)
					fo.puts seq.translate(4).to_fasta(id + " [strand=#{seq.strand * -1};frame=1]", 60)
					fo.puts seq.translate(5).to_fasta(id + " [strand=#{seq.strand * -1};frame=2]", 60)
					fo.puts seq.translate(6).to_fasta(id + " [strand=#{seq.strand * -1};frame=3]", 60)
				end
			end
			fo.close
		end
	end
	
	class Seq < Item
		attr_accessor :isolate, :strain, :clone, :country, :subid, :accession, :translation
		attr_accessor :source, :locus, :strand, :from, :to, :description, :pseudogene, :sequence, :trans_table, :type

		def initialize(id)
			super
			
			@pseudogene = 0
			# Assume the default and pray we can get the information somewhere.
			@trans_table = 1
			# For isolates we usually get the translation from the CDS, and this is stored in the @translation holder.
			# There is a method translate() that computes a translation based on the corresponding cds. It accepts
			# a different frame and translation table.
			@translation = nil
		end
		
		def size
			sequence.length
		end
		
		# This method is very simple since we assume that there is not exon information in isolated sequences. This
		# might be revisited in the future and then the method will mimic the one in Genome::Gene. But right now, it
		# just takes into account the from and to values, plus the strandness. In fact, I am not sure if isolate
		# sequences use different strands at all (which makes the whole thing even simpler).
		def splicing
			x0 = from - from + 1
			x1 = to - from + 1
			loc = x0.to_s + ".." + x1.to_s
			
			loc = "complement(" + loc + ")" if strand == -1
			loc
		end
		
		# Returns the splicing pattern based on the locus coordinates, i.e. this is the original splicing pattern found
		# in the Genbank entry.
		def splicing_original
			loc = from.to_s + ".." + to.to_s
			loc = "complement(" + loc + ")" if strand == -1
			loc
		end
		
		# Returns the CDS based on the splicing pattern.
		def cds
			sequence.splice(splicing)
		end
		
		# Translates the CDS sequence. Can be specified the frame and tanslation table.
		def translate(frame = 1, table = nil)
			if table
				t = Bio::CodonTable[table]
			else
				t = Bio::CodonTable[@trans_table.to_i]
			end
			cds.translate(frame, t)
		end

		def debug
			warn "+ Sequence +"
			warn "* id: " + id
			warn "* subid: " + subid
			warn "* locus: " + locus
			warn "* accession: " + accession
			warn "* description: " + description
			warn "* source: " + source
			warn "* strand: " + strand.to_s
			warn "* location: [" + from.to_s + " - " + to.to_s + "]"
			warn "* splicing: " + splicing
			warn "* splicing_ori: " + splicing_original
			warn "* pseudogene: " + pseudogene.to_s
			warn "* type: " + type
			warn "* trans_table: " + trans_table.to_s
			warn ""
		end
	end
end