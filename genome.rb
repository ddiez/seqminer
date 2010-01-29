require 'seqminer'
require 'item'
require 'sequence'

# SeqMiner is a tool for mining sequence information. It aims
# to help detect sequences belonging to specific protein fa-
# milies.
#
# Author::    Diego Diez  (mailto:diez@kuicr.kyoto-u.ac.jp)
# Copyright:: Copyright (c) 2010
# License::   Distributes under the same terms as Ruby

module Genome
	include Item

	# Holder for Genome information
	#
	# * contains taxon information
	# * is is derived from class Set in module Item
	class Set < Set
		attr_accessor :chromosome
		attr_reader :config, :name, :file, :taxon

		def initialize(taxon, options = {:empty => false, :config => nil})
			super()
			
			@taxon = taxon
			@name = taxon.name
			@chromosome = {}

			if options[:config]
				@config = options[:config]
			else
				@config = SeqMiner::Config.new
			end

			if options[:empty]
				@file = "_undef_"
			else
				gdb = Sequence::Set.new(name, "gene", options = {:config => config})
	
				file = config.dir_sequence + name + "genome.txt"
				@file = file
				
				fi = File.open(file, "r")
				fi.each do |line|
					next if line.match(/^id\t/)
					id, chromosome, source, type, exon, strand, from, to, pseudogene, references, mol_type, description = line.split("\t")
					if type == "gene"
						gene = Gene.new(id)
						gene.chromosome = chromosome
						gene.source = source
						gene.strand = strand.to_i
						gene.from = from.to_i
						gene.to = to.to_i
						gene.pseudogene = pseudogene
						gene.references = references
						gene.type = mol_type
						gene.description = description
						seq = gdb.get_item_by_id(id)
						gene.sequence = seq
						add(gene)
					elsif type == "exon"
						gene = get_gene_by_acc(id)
						if ! gene.nil?
							exon = Exon.new(exon)
							exon.strand = strand.to_i
							exon.from = from.to_i
							exon.to = to.to_i
							gene << exon
						else
							raise "ERROR: gene #{acc} not found for exon #{acc}"
						end
					end
				end
				fi.close
			end
		end
		
		def _parse_desc(line)
			valid_fields = ["description", "pseudogene"]
			a = line.split(/=|;/)
			h = {}
			valid_fields.each do |field|
				fi = a.index(field)
				if ! fi.nil?
					h[field] = a[fi + 1]
				end
			end
			h
		end
		
		def each_gene
			items.each_value do |value|
				yield value
			end
		end
		
		def auto_clean
			items.delete_if do |id, gene|
				gene.size < 5 # This is because it give us at least one residue in the 6frame translations.
			end
		end

		# returns a gene item based on the accession value.
		def get_gene_by_acc(acc)
			get_item_by_id(acc)
		end

		def filter_by_acc(acc)
			items.delete_if do |id, gene|
				! acc.include?(id)
			end
		end
		
		def write_fasta(type, file = nil)
			if file
				fo = File.new(file, "w")
			else
				fo = $stdout
			end
			
			case type
			when 'gene'
				items.each_value do |gene|
					id = gene.id + " " + gene.description
					seq = gene.sequence
					fo.puts seq.to_fasta(id, 60)
				end
			when 'cds'
				items.each_value do |gene|
					id = gene.id + " " + gene.description
					seq = gene.cds
					fo.puts seq.to_fasta(id, 60)
				end
			when 'protein'
				items.each_value do |gene|
					id = gene.id + " " + gene.description
					seq = gene.translation
					fo.puts seq.to_fasta(id, 60)
				end
			when '6frame'
				items.each_value do |gene|
					id = gene.id + " " + gene.description
					seq = gene.translation(1)
					fo.puts seq.to_fasta(id + " [strand=#{gene.strand};frame=1]", 60)
					seq = gene.translation(2)
					fo.puts seq.to_fasta(id + " [strand=#{gene.strand};frame=2]", 60)
					seq = gene.translation(3)
					fo.puts seq.to_fasta(id + " [strand=#{gene.strand};frame=3]", 60)
					seq = gene.translation(4)
					fo.puts seq.to_fasta(id + " [strand=#{gene.strand * -1};frame=1]", 60)
					seq = gene.translation(5)
					fo.puts seq.to_fasta(id + " [strand=#{gene.strand * -1};frame=2]", 60)
					seq = gene.translation(6)
					fo.puts seq.to_fasta(id + " [strand=#{gene.strand * -1};frame=3]", 60)
				end
			when 'genome'
				chromosome.each_pair do |id, chr|
					next if chr.length == 0 # to filter non-contig segments.
					fo.puts chr.to_fasta(id, 60)
				end
			end
			fo.close
		end

		def write_gff(file = nil)
			if file
				fo = File.new(file, "w")
			else
				fo = $stdout
			end

			items.each_value do |gene|
				desc = []
				desc << "description=" + gene.description
				desc << "type=" + gene.type
				desc << "pseudogene=" + gene.pseudogene.to_s
				desc = desc.join(";")

				fo.puts gene.id + "\t" + \
					gene.source + "\t" + \
					"gene" + "\t" + \
					gene.chromosome + "\t" + \
					gene.strand.to_s + "\t" + \
					gene.from.to_s + "\t" + \
					gene.to.to_s + "\t" + \
					"-" + "\t" + \
					desc
				gene.oitems.each do |exon|
					fo.puts gene.id + "\t" + \
						gene.source + "\t" + \
						"exon" + "\t" + \
						"-" + "\t" + \
						exon.strand.to_s + "\t" + \
						exon.from.to_s + "\t" + \
						exon.to.to_s + "\t" + \
						exon.id.to_s + "\t" + \
						"-"
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
				"chromosome\t" +
				"source\t" +
				"type\t" +
				"exon\t" +
				"strand\t" +
				"from\t" +
				"to\t" +
				"pseudogene\t" +
				"references\t" +
				"mol_type\t" +
				"description"
			each_gene do |gene|
				fo.puts gene.id + "\t" +
					gene.chromosome + "\t" +
					gene.source + "\t" +
					"gene" + "\t" +
					"\t" +
					gene.strand.to_s + "\t" +
					gene.from.to_s + "\t" +
					gene.to.to_s + "\t" +
					gene.pseudogene.to_s + "\t" +
					gene.references.to_s + "\t" +
					gene.type + "\t" +
					gene.description
				gene.oitems.each do |exon|
					fo.puts gene.id + "\t" +
						"\t" +
						"\t" +
						"exon" + "\t" +
						exon.id.to_s + "\t" +
						exon.strand.to_s + "\t" +
						exon.from.to_s + "\t" +
						exon.to.to_s + "\t" +
						"\t" +
						"\t" +
						"\t" +
						""
				end
			end
			fo.close
		end
		
		def debug
			warn "+ Genome +"
			warn "* file: " + file
			warn "* name: " + name
			warn "* genes: " + length.to_s
		end
	end
	
	class Gene < Item
		attr_accessor :source, :chromosome, :strand, :from, :to, :description, :pseudogene, :sequence
		attr_accessor :trans_table, :type, :references
		attr_reader :oitems, :size

		def initialize(id)
			super
			@pseudogene = 0
			@trans_table = 1 # assume the default and pray we can get the information somewhere.
			@oitems = []
		end

		def cds
			#debug(verbose = TRUE)
			sequence.splice(splicing)
		end

		def size
			sequence.length
			#to.to_i - from.to_i
		end
		
		# A synonim to the method #translate
		def translation(frame = 1, table = nil)
			translate(frame, table)
		end
		
		def translate(frame = 1, table = nil)
			if table
				t = Bio::CodonTable[table]
			else
				t = Bio::CodonTable[@trans_table.to_i]
			end
			cds.translate(frame, t)
		end
		
		# This methods returns the splicing pattern in gene coordinates. In other words, it is used to extract
		# the exonic sequence (and potentially the introns) from the gene sequence.
		def splicing
			loc =[]
			
			case strand
			when 1
				exons = oitems
			when -1
				exons = oitems.reverse
			end
			
			f0 = exons[0].from
			exons.each do |exon|
				x0 = exon.from - f0 + 1
				x1 = exon.to - f0 + 1
				loc << x0.to_s + ".." + x1.to_s
			end
			loc = loc.join(",")
			loc = "join(" + loc + ")" if length > 1
			loc = "complement(" + loc + ")" if strand == -1
			loc
		end
		
		# This methods displays the original splicing pattern based on the genomic coordinates. It can be used to 
		# extract the exons from the genome sequence. It is intended mainly as a check method.
		def splicing_original
			loc =[]
						
			case strand
			when 1
				exons = oitems
			when -1
				exons = oitems.reverse
			end
			
			#f0 = exons[0].from
			exons.each do |exon|
				x0 = exon.from #- f0 + 1
				x1 = exon.to #- f0 + 1
				loc << x0.to_s + ".." + x1.to_s
			end
			loc = loc.join(",")
			loc = "join(" + loc + ")" if length > 1
			loc = "complement(" + loc + ")" if strand == -1
			loc
		end
		
		def << (exon)
			add(exon)
		end
		
		def add(exon)
			@oitems << exon
			super(exon)
		end

		def debug(verbose = false)
			warn "+ Gene +"
			warn "* id: " + id
			warn "* description: " + description
			warn "* source: " + source
			warn "* chromosome: " + chromosome
			warn "* strand: " + strand.to_s
			warn "* location: [" + from.to_s + " - " + to.to_s + "]"
			warn "* exons: " + length.to_s
			warn "* splicing: " + splicing
			warn "* size: " + size.to_s
			#warn "* splicing_ori: " + splicing_original
			warn "* pseudogene: " + pseudogene.to_s
			if verbose
				each_value do |exon|
					exon.debug
				end
			end
		end
	end

	class Exon < Item
		attr_accessor :strand, :from, :to, :location
		# TODO: do i need parent method (like in perl API) ?

		def initialize(id)
			super
		end

		def debug
			warn "+ Exon +"
			warn "* id: " + id.to_s
			warn "* strand: " + strand.to_s
			warn "* location: (" + from.to_s + ".." + to.to_s + ")"
		end
	end
end
