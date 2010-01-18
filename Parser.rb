require 'bio'
require 'uri'
require 'Genome'

module Parser
	class Refseq
		attr_reader :file, :name, :config, :sequence
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

			warn "* processing Genbank file: " + file
			p = Bio::GenBank.open(file)

			chr = {}
			genome.chromosome = chr
			p.each_entry do |gb|
				#puts gb.accession
				#puts gb.organism
				#puts gb.definition

				@sequence = gb.seq
				chr[gb.accession] = sequence

				gb.features.each do |feat|
					if feat.feature == "gene"
						h = feat.to_hash
						id = h['locus_tag']
						gene = genome.get_gene_by_acc(id[0])
						if gene.nil?
							gene = Genome::Gene.new(id[0])
							gene.strand = feat.locations[0].strand
							gene.from = feat.locations[0].from
							gene.to = feat.locations[0].to
							gene.sequence = sequence.subseq(gene.from, gene.to)
							gene.description = ""
							gene.source = "refseq"
							gene.chromosome = gb.accession
							genome << gene

							if h['pseudo']
								gene.pseudogene = 1
								gene.type = "CDS" # or make another category?
								
								exon = Genome::Exon.new(gene.length + 1)
								exon.strand = feat.locations[0].strand
								exon.from = feat.locations[0].from
								exon.to = feat.locations[0].to
								gene << exon
							end
						end
					elsif feat.feature == "CDS"
						h = feat.to_hash
						id = h['locus_tag']
						gene = genome.get_gene_by_acc(id[0])
						gene.trans_table = h['trans_table'] if h['trans_table']
						if gene.nil?
							warn "ERROR: gene #{id} not found for this CDS!"
						else
							gene.description = h['product'][0] if h['product']
							gene.type = feat.feature

							locs = feat.locations
							locs.each do |loc|
								exon = Genome::Exon.new(gene.length + 1)
								exon.strand = loc.strand
								exon.from = loc.from
								exon.to = loc.to
								gene << exon
							end
						end
					elsif feat.feature == "tRNA" or feat.feature == "rRNA" or feat.feature == "tmRNA" or feat.feature == "misc_RNA" or feat.feature == "ncRNA" or feat.feature == "misc_feature"
						h = feat.to_hash
						if h['locus_tag']
							id = h['locus_tag']
							gene = genome.get_gene_by_acc(id[0])
							if gene.nil?
								warn "ERROR: gene #{id} not found for this CDS!"
							else
								if h['produc']
									gene.description = h['product'][0]
								elsif h['gene']
									gene.description = h['gene'][0]
								elsif h['note']
									gene.description = h['note'][0]
								end
								gene.type = feat.feature

								locs = feat.locations
								locs.each do |loc|
									exon = Genome::Exon.new(gene.length + 1)
									exon.strand = loc.strand
									exon.from = loc.from
									exon.to = loc.to
									gene << exon
								end
							end
						end
					end
				end
			end
			genome.chromosome = chr
			genome
		end
	end

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
			chrs = {}
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
				elsif record.feature == "CDS" or record.feature == "tRNA" or record.feature == "rRNA"
					parent_id = _parse_exon_attributes(record.attributes)
					gene = genome.get_gene_by_acc(parent_id)
					if ! gene.nil?
						gene.type = record.feature
					else
						raise "ERROR: gene #{parent_id} not found for exon #{parent_id}"
					end
				elsif record.feature == "mRNA"
					# skip this.
				elsif record.feature == "transcript"
					gene.type = "CDS"
				elsif record.feature == "supercontig"
					# TODO: add extra info (start, end)
					chrs[record.seqname.sub(/^.+?\|(.+)/, '\1')] = sequences[record.seqname]
				else
					$stderr.puts "%%%%%%% " + record.feature
				end
			end
			genome.chromosome = chrs
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
			#id = f["ID"]
			#id.sub!(/^.+\|/, '')
			id = f['locus_tag']
			desc = _unescape(f['description'])
			pseudo = 1 if desc.match('pseudogene')
			[id, desc, pseudo]
		end

		def _parse_exon_attributes(c)
			parent = nil
			c = _array2hash(c)

			#if name.match("plasmodium.vivax_salvador1") 
				parent = c["ID"]
				parent.sub!(/.+?_(.+)-.+$/, '\1')
			#else
				#parent = c["Parent"]
				#parent.sub!(/^.+?_(.+)-.+$/, '\1')
			#end
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
