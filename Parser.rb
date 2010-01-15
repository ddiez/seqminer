require 'bio'
require 'uri'
require 'Genome'

module Parser
	class Eupathdb
		attr_reader :file, :name, :config, :sequences
		
		def initialize(file, name, options = {:config => nil})
			@file = file
			@name = name

			if ! options[:config]
				@config = SeqMiner::Config.new
			else
				@config = options[:config]
			end
		end
		
		def parse
			genome = Genome::Set.new(name, options = {:empty => true})

			warn "* processing GFF file: " + file
			p = Bio::GFF::GFF3.new(File.open(file, "r"))
			
			@sequences = {} 
			p.sequences.each do |seq|
				seq.na
				@sequences[seq.entry_id] = seq
			end
			
			p.records.each do |record|
				if record.feature == "gene"
					chr = record.seqname.sub(/.+\|(.+)/, '\1')
					(id, desc, pseudo) = _parse_gene_attributes(record.attributes)
					
					gene = Genome::Gene.new(id)
					gene.chromosome = chr
					gene.source = record.source
					gene.strand = _get_strand(record.strand)
					gene.from = record.start.to_i
					gene.to = record.end.to_i
					gene.description = desc
					gene.pseudogene = pseudo
					gene.sequence = sequences[record.seqname].subseq(record.start, record.end)
					
					genome << gene
				elsif record.feature == "exon"
					parent_id = _parse_exon_attributes(record.attributes)
					gene = genome.get_gene_by_acc(parent_id)
					if ! gene.nil?
						exon = Genome::Exon.new(gene.length + 1)
						exon.strand = _get_strand(record.strand)
						exon.from = record.start.to_i
						exon.to = record.end.to_i
						gene << exon
					else
						raise "ERROR: gene #{parent_id} not found for exon #{parent_id}"
					end
				elsif record.feature == "supercontig"
					# TODO: do I need this?
				end
			end
			genome
		end
		
		def _unescape(str)
			str = URI.unescape(str)
			str.gsub!(/\+/, ' ')
			str
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
		
		def _parse_gene_attributes(c)
			id = nil
			desc = ""
			pseudo = 0
			f = _array2hash(c)
			id = f["ID"]
			id.sub!(/.+\|/, '')
			desc = _unescape(f["description"])
			pseudo = 1 if desc.match("pseudogene")
			[id, desc, pseudo]
		end
		
		def _parse_exon_attributes(c)
			parent = nil
			c = _array2hash(c)
			
			parent = c["ID"]
			parent.sub!(/.+exon_(.+)-.+$/, '\1')
			parent
		end
		
		def _array2hash(a)
			h = {}
			a.each do |val|
				h[val[0]] = val[1]
			end
			h
		end
	end
end