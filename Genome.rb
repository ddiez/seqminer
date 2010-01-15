require 'SeqMiner'
require 'Item'
require 'Sequence'

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
		attr_reader :config, :name, :file

		def initialize(name, options = {:empty => false, :config => nil})
			super()
			
			@name = name

			if ! options[:config]
				@config = SeqMiner::Config.new
			else
				@config = options[:config]
			end

			if options[:empty]
				@file = "_undef_"
			else
				gdb = Sequence::Set.new(name, "gene")
	
				file = config.dir_genome + name + "genome.gff"
				@file = file
	
				fi = File.open(file, "r")
				fi.each do |line|
					line.chomp
					(acc, source, type, chr, strand, s0, s1, foo, desc) = line.split("\t")
					if type == 'gene'
						gene = Gene.new(acc)
						gene.source = source
						gene.chromosome= chr
						gene.strand = _get_strand(strand)
						gene.from = s0
						gene.to = s1
						
						if desc.nil?
							desc = ""
						else
							desc = _parse_desc(desc)
						end
						gene.description = desc["description"]
	
						if desc["pseudogene"]
							gene.pseudogene = desc["pseudogene"]
						end
	
						seq = gdb.get_item_by_id(acc)
						gene.sequence = seq
	
						add(gene)
					elsif type == "exon"
						gene = get_gene_by_acc(acc)
						if ! gene.nil?
							exon = Exon.new(gene.length + 1)
							exon.strand = _get_strand(strand)
							exon.from = s0.to_i
							exon.to = s1.to_i
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

		# returns a gene item based on the accession value.
		def get_gene_by_acc(acc)
			get_item_by_id(acc)
		end
		
		def _get_strand(s)
			if s == "+"
				return 1
			elsif s == "-"
				return -1
			else
				return nil
			end
		end
		
		def write_fasta(type)
			items.each_value do |gene|
				gene.debug
				case type
				when 'gene'
					seq = gene.sequence
				when 'cds'
					seq = gene.cds
				when 'protein'
					seq = gene.translation
				end
				puts seq.to_fasta(gene.id + " " + gene.description, 60)
			end
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
		attr_reader :oitems

		def initialize(id)
			super
			@pseudogene = 0
			@oitems = []
		end

		def cds
			sequence.splice(splicing)
		end
		
		def translation(phase = 1)
			cds.translate(phase)
		end

#		def splicing_old
#			loc = []
#			f0 = 0
#			items.sort.each_index do |index|
#				if (index == 0)
#					f0 = items[index+1].from
#				end
#				x0 = items[index+1].from - f0 + 1
#				x1 = items[index+1].to - f0 + 1
#				loc << x0.to_s + ".." + x1.to_s
#			end
#			loc = loc.join(",")
#			loc = "join(" + loc + ")" if length > 1
#			loc = "complement(" + loc + ")" if strand == -1 # in the current version this is not needed.
#			loc
#		end
		
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
			loc = "complement(" + loc + ")" if strand == -1 # in the current version this is not needed.
			loc
		end
		
#		def splicing_original
#			loc = []
#			items.sort.each_index do |index|
#				x0 = items[index+1].from
#				x1 = items[index+1].to
#				loc << x0.to_s + ".." + x1.to_s
#			end
#			loc = loc.join(",")
#			loc = "join(" + loc + ")" if length > 1
#			loc = "complement(" + loc + ")" if strand == -1
#			loc
#		end
		
		def << (exon)
			add(exon)
		end
		
		def add(exon)
			@oitems << exon
			super(exon)
		end

		def debug
			warn "+ Gene +"
			warn "* id: " + id
			warn "* description: " + description
			warn "* source: " + source
			warn "* chromosome: " + chromosome
			warn "* strand: " + strand.to_s
			warn "* location: [" + from.to_s + " - " + to.to_s + "]"
			warn "* splicing: " + splicing
			#warn "* splicing_ori: " + splicing_original
			warn "* pseudogene: " + pseudogene.to_s
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
