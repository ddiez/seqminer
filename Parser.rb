require 'bio'
require 'uri'
require 'Genome'

module Parser
	class Common
		attr_accessor :file, :name
		attr_reader :config, :taxon, :subtype
		
		def initialize(taxon, options = {:config => nil})
			if options[:subtype]
				@subtype = options[:subtype]
			else
				@subtype = nil
			end
			
			if options[:config]
				@config = options[:config]
			else
				@config = SeqMiner::Config.new
			end
		
			@taxon = taxon	
			@name = taxon.name
		end
	end

	class Refseq < Common
		
		def initialize(taxon, options = {:config => nil})
			super
			
			@file = config.dir_source + taxon.name + (taxon.name + ".gb")
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

				chr[gb.accession] = gb.seq

				
				u = {}
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
							gene.sequence = gb.seq.subseq(gene.from, gene.to)
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
					elsif feat.feature == "tRNA" or feat.feature == "rRNA" or feat.feature == "tmRNA" or \
						feat.feature == "misc_RNA" or feat.feature == "ncRNA" or feat.feature == "misc_feature" or \
						feat.feature == "mRNA"
						
						next if taxon.name == "ehrlichia.ruminantium_welgevonden" and feat.feature == "misc_feature"
						
						h = feat.to_hash
						if h['locus_tag']
							id = h['locus_tag']
							gene = genome.get_gene_by_acc(id[0])
							if gene.nil?
								warn "ERROR: gene #{id} not found for this CDS!"
							else
								if h['product']
									gene.description = h['product'][0]
								elsif h['gene']
									gene.description = h['gene'][0]
								elsif h['note']
									gene.description = h['note'][0]
								end
								
								next if feat.feature == "mRNA"

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
					elsif feat.feature == "repeat_region" or \
						feat.feature == "RBS" or feat.feature == "source"
						# skip.
					else
						if u.has_key?(feat.feature) 
							u[feat.feature] += 1
						else
							u[feat.feature] = 1
						end
					end
				end
				puts "+++ " + gb.accession if u.length > 0
				u.each_pair do |feat, count|
					puts "+++ " + feat + ": " + count.to_s
				end
			end
			genome.chromosome = chr
			genome
		end
	end
	
	class Broad < Common
		def initialize(taxon, options = {:config => nil})
			super
			
			@file = config.dir_source + taxon.name + (taxon.name + ".gb")
		end

		def parse
		end
	end

	class Eupathdb < Common

		def initialize(taxon, options = {:config => nil})
			super
			
			if subtype
				@file = config.dir_source + taxon.name + (taxon.name + "-" + subtype + ".gff")
			else
				@file = config.dir_source + taxon.name + (taxon.name + ".gff")
			end
		end

		def parse
			puts "* file: " + file
			
			genome = Genome::Set.new(name, options = {:empty => true})

			warn "* processing GFF file: " + file
			p = Bio::GFF::GFF3.new(File.open(file, "r"))

			sequences = {}
			chrs = {}
			p.sequences.each do |seq|
				seq.na
				sequences[seq.entry_id] = seq
			end

			p.records.each do |record|
				if record.feature == "gene"
					chr = record.seqname.sub(/.+\|(.+)/, '\1')
					attr = _parse_attributes(record.attributes, record.feature)

					gene = Genome::Gene.new(attr[:id])
					gene.chromosome = chr
					gene.source = record.source
					gene.strand = _get_strand(record.strand)
					gene.from = record.start.to_i
					gene.to = record.end.to_i
					gene.description = attr[:desc]
					gene.pseudogene = attr[:pseudo]
					gene.sequence = sequences[record.seqname].subseq(record.start, record.end)
					genome << gene
				elsif record.feature == "exon"
					attr = _parse_attributes(record.attributes, record.feature)
					gene = genome.get_gene_by_acc(attr[:parent])
					if ! gene.nil?
						exon = Genome::Exon.new(gene.length + 1)
						exon.strand = _get_strand(record.strand)
						exon.from = record.start.to_i
						exon.to = record.end.to_i
						gene << exon
					else
						raise "ERROR: parent " + attr[:parent] + " not found for child " + attr[:id]
					end
				elsif record.feature == "CDS" or record.feature == "tRNA" or record.feature == "rRNA" or \
					record.feature == "snRNA" or record.feature == "transcript" or record.feature == "ncRNA" or \
					record.feature == "scRNA_encoding"
					
					attr = _parse_attributes(record.attributes, record.feature)
					gene = genome.get_gene_by_acc(attr[:parent])
					if ! gene.nil?
						if record.feature == "transcript"
							gene.type = "CDS"
						else
							gene.type = record.feature
						end
					else
						raise "ERROR: parent " + attr[:parent] + " not found for child " + attr[:id]
					end
				elsif record.feature == "mRNA"
					# skip this.
				#elsif record.feature == "transcript"
					#gene.type = "CDS"
				elsif record.feature == "supercontig"
					# TODO: add extra info (start, end)
					id = record.seqname.sub(/^.+\|(.+)/, '\1')
					chrs[id] = sequences[record.seqname]
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

		def _parse_attributes(c, type)
			f = _array2hash(c)
			h = {
				:id => nil,
				:parent => nil,
				:desc => "",
				:pseudo => 0
			}

			h[:id] = f["ID"]
			h[:id].sub!(/^.+\|/, "")

			if f["Parent"]
				h[:parent] = f["Parent"]
				h[:parent].sub!(/^.+\|/, "")
			end

			if taxon.name == "plasmodium.vivax_salvador1"
				h[:parent] = f["ID"]
				h[:parent].sub!(/^.+?_(.+)-.+$/, '\1')
			end
			
			case type
			when "supercontig", "gene"
			when "tRNA", "mRNA", "transcript", "ncRNA", "scRNA_encoding"
				h[:id].sub!(/^.+?_(.+)-.+$/, '\1')
			when "exon", "CDS"
				h[:id].sub!(/^.+?_(.+)-.+$/, '\1')
				h[:parent].sub!(/^.+?_(.+)-.+$/, '\1')
			end			
		
			if f["description"]
				h[:desc] = _unescape(f["description"])
			end

			h[:pseudo] = 1 if h[:desc].match('pseudogene')
			
			h
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
