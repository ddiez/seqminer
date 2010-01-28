require 'seqminer'
require 'item'
require 'sequence'

module Isolate
	include Item

	class Set < Set
		attr_accessor :locus
		attr_reader :config, :name, :file, :taxon
		
		def initialize(taxon, options = {:empty => false, :config => nil})
			super()
			
			@taxon = taxon
			@name = taxon.name
			@locus = {}
			
			if options[:config]
				@config = options[:config]
			else
				@config = SeqMiner::Config.new
			end
			
			if options[:empty]
				@file = "_undef_"
			else
				gdb = Sequence::Set.new(name, "gene", options = {:config => config})
	
				file = config.dir_sequence + name + "isolate.txt"
				@file = file
				
				fi = File.open(file, "r")
				fi.each do |line|
					next if line.match(/^id\t/)
					id, accession, subid, locus, source, isolate, strain, clone, country, type, pseudogene, \
						strand, from, to, trans_table, references, description = line.split("\t")
					seq = Isolate::Seq.new(id)
					seq.accession = accession
					seq.subid = subid
					seq.locus = locus
					seq.source = source
					seq.isolate = isolate
					seq.strand = strain
					seq.clone = clone
					seq.country = country
					seq.type = type
					seq.pseudogene = pseudogene.to_i
					seq.strand = strand.to_i
					seq.from = from.to_i
					seq.to = to.to_i
					seq.trans_table = trans_table
					seq.references = references
					seq.description = description
					gseq = gdb.get_seq_by_acc(id)
					seq.sequence = gseq
					add(seq)
				end
			end
		end
		
		def each_sequence
			items.each_value do |value|
				yield value
			end
		end
		
		def filter_by_acc(acc)
			items.delete_if do |id, iso|
				! acc.include?(id)
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
				seq.size < 5 # This is because this give us at least one residue in the different translations.
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
				each_sequence do |seq|
					id = seq.id + " accession=" + seq.accession + ";source=" + seq.source + ";type=" + \
						seq.type + ";description=" + seq.description + ";"
					fo.puts seq.sequence.to_fasta(id, 60)
				end
			when "cds"
				each_sequence do |seq|
					id = seq.id + " accession=" + seq.accession + ";source=" + seq.source + ";type=" + \
						seq.type + ";description=" + seq.description + ";"
					fo.puts seq.cds.to_fasta(id, 60)
				end
			when "protein"
				each_sequence do |seq|
					next if ! seq.translation
					id = seq.id + " accession=" + seq.accession + ";source=" + seq.source + ";type=" + \
						seq.type + ";trans_table=" + seq.trans_table.to_s + ";description=" + seq.description + ";"
					fo.puts seq.translation.to_fasta(id, 60)
				end
			when '6frame'
				each_sequence do |seq|
					id = seq.id + " accession=" + seq.accession + ";source=" + seq.source + ";type=" + \
						seq.type + ";trans_table=" + seq.trans_table.to_s + ";description=" + seq.description + ";"
					fo.puts seq.translate(1).to_fasta(id + " [strand=#{seq.strand};frame=1]", 60)
					fo.puts seq.translate(2).to_fasta(id + " [strand=#{seq.strand};frame=2]", 60)
					fo.puts seq.translate(3).to_fasta(id + " [strand=#{seq.strand};frame=3]", 60)
					fo.puts seq.translate(4).to_fasta(id + " [strand=#{seq.strand * -1};frame=1]", 60)
					fo.puts seq.translate(5).to_fasta(id + " [strand=#{seq.strand * -1};frame=2]", 60)
					fo.puts seq.translate(6).to_fasta(id + " [strand=#{seq.strand * -1};frame=3]", 60)
				end
			when 'isolate'
				locus.each_pair do |id, loc|
					fo.puts loc.to_fasta(id, 60)
				end
			end
			fo.close
		end
		
		def write_table(file = nil)
			if file
				fo = File.new(file, "w")
			else
				fo = $stdout
			end
			
			fo.puts "id\t" +
				"accession\t" +
				"subid\t" +
				"locus\t" +
				"source\t" +
				"isolate\t" +
				"strain\t" +
				"clone\t" +
				"country\t" +
				"type\t" +
				"pseudogene\t" +
				"strand\t" +
				"from\t" +
				"to\t" +
				"trans_table\t" +
				"references\t" +
				"description"
			each_sequence do |seq|
				fo.puts seq.id + "\t" +
					seq.accession + "\t" +
					seq.subid + "\t" +
					seq.locus + "\t" +
					seq.source + "\t" +
					seq.isolate.to_s + "\t" +
					seq.strain.to_s + "\t" +
					seq.clone.to_s + "\t" +
					seq.country.to_s + "\t" +
					seq.type + "\t" +
					seq.pseudogene.to_s + "\t" +
					seq.strand.to_s + "\t" +
					seq.from.to_s + "\t" +
					seq.to.to_s + "\t" +
					seq.trans_table.to_s + "\t" +
					seq.references + "\t" +
					seq.description
			end
			fo.close
		end
	end
	
	class Seq < Item
		attr_accessor :accession, :subid, :locus, :source, :isolate, :strain, :clone, :country
		attr_accessor :type, :pseudogene, :strand, :from, :to, :trans_table, :references, :description
		attr_accessor :sequence, :translation

		def initialize(id)
			super
			
			@pseudogene = 0
			# Assume the default and pray we can get the information somewhere.
			@trans_table = nil
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