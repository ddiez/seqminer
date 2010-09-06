# SeqMiner is a tool for mining sequence information. It aims to
# help detect sequences belonging to specific protein families.
#
# Author::    Diego Diez  (mailto:diez@kuicr.kyoto-u.ac.jp)
# Copyright:: Copyright (c) 2010
# License::   Distributes under the same terms as Ruby

require 'bio'
require 'uri'
require 'genome'
require 'isolate'

# === This module contains parsers for the genome and sequence formats
# 1. GenbankIsolate
# 2. Refseq
# 3. Eupathdb
# 4. Broad Institute

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
				@config = Config::General.new
			end
		
			@taxon = taxon	
			@name = taxon.name
		end
	end
	
	class GenbankIsolate < Common
		attr_reader :files
			
		def initialize(taxon, options = {:config => nil})
			super
			
			@files = {
				:nuccore => config.dir_source + taxon.name + (taxon.name + "_nuccore.gb"),
				:nucest => config.dir_source + taxon.name + (taxon.name + "_nucest.gb")
			}
		end

		def parse
			is = Isolate::Set.new(taxon, options = {:empty => true})
			
			feats = []
			chrs = {}
			files.each_pair do |type, file|
				next if ! file.exist?
				warn "* processing Genbank [" + type.to_s + "] file: " + file
				p = Bio::GenBank.open(file)
				
				skip = File.new(config.dir_source + taxon.name + (type.to_s + "_skip.txt"), "w")
				pass = File.new(config.dir_source + taxon.name + (type.to_s + "_pass.txt"), "w")
				
				skip.puts "LOCUS\tDivision\tLength\tWhy\tIsolate\tStrain\tCountry\tClone\tOrganelle"
				pass.puts "LOCUS\tDivision\tLength\tIsolate\tStrain\tCountry\tClone\tOrganelle"
				p.each_entry do |gb|
					next if gb.accession == ""
					
					chrs[gb.accession] = gb.seq

					refs = gb.references
					ref = []
					refs.each do |r|
						ref << r.pubmed if r.pubmed != ""
					end
					ref = ref.join(";")

					#warn "* processing: " + gb.accession
					strain = _check_in_source(gb, "strain")
					isolate = _check_in_source(gb, "isolate")
					country = _check_in_source(gb, "country")
					clone = _check_in_source(gb, "clone")
					organelle = _check_in_source(gb, "organelle")

					ok, why = _filter_entry(gb)
					if ok
						pass.puts gb.accession + "\t" + gb.division + "\t" + gb.length.to_s + "\t" + isolate.to_s + "\t" + strain.to_s + "\t" + country.to_s + "\t" + clone.to_s + "\t" + organelle.to_s
						fa = 0
						gb.features.each do |feat|
							feats << feat.feature
							if type == :nuccore
								if feat.feature == "gene"
									h = feat.to_hash
									
									id = nil
									acc = ""
									desc = ""
									if h['locus_tag']
										# These are suspicious to be present in genome projects but there are some 
										# situations where this is not the case so we maintain them.
										id = gb.accession + "|" + h['locus_tag'][0]
										acc = h['locus_tag'][0]
									elsif h['gene']
										id = gb.accession + "|" + h['gene'][0]
										desc = h['gene'][0]
										#acc = h['gene'][0]
									else
										warn "******* NOT VALID TAG TO CREATE <gene> ENTRY IN LOCUS: " + gb.accession
										next
									end
									
									seq = Isolate::Seq.new(gb.accession + "-" + (fa + 1).to_s)
									seq.subid = id
									seq.accession = acc
									seq.strand = feat.locations[0].strand.to_i
									seq.from = feat.locations[0].from.to_i
									seq.to = feat.locations[0].to.to_i
									seq.locus = gb.accession
									seq.source = type.to_s
									seq.trans_table = taxon.trans_table
									seq.references = ref
									seq.division = gb.division
									if h['note']
										seq.description = h['note'][0]
									else
										seq.description = desc
									end
									seq.type = "gene"
									seq.pseudogene = 1 if h['pseudo']
									seq.sequence = gb.seq.subseq(seq.from, seq.to)
									is << seq
									fa += 1
								elsif feat.feature == "CDS"
									h = feat.to_hash
									
									seq = nil
									if h['locus_tag']
										id = gb.accession + "|" + h['locus_tag'][0]
										seq = is.get_seq_by_subid(id)
									elsif h['gene']
										id = gb.accession + "|" + h['gene'][0]
										seq = is.get_seq_by_subid(id)
									end
									
									if ! seq
										if h['protein_id']
											id = gb.accession + "|" + h['protein_id'][0]
											
											seq = Isolate::Seq.new(gb.accession + "-" + (fa + 1).to_s)
											seq.subid = id
											seq.accession = h['protein_id'][0]
											seq.strand = feat.locations[0].strand.to_i
											seq.from = feat.locations[0].from.to_i
											seq.to = feat.locations[0].to.to_i
											seq.locus = gb.accession
											seq.source = type.to_s
											seq.sequence = gb.seq.subseq(seq.from, seq.to)
											seq.trans_table = taxon.trans_table
											seq.references = ref
											seq.division = gb.division
											is << seq
											fa += 1
										else
											id = gb.accession + "-" + (fa + 1).to_s
											
											seq = Isolate::Seq.new(id)
											seq.subid = id
											seq.accession = ""
											seq.strand = feat.locations[0].strand.to_i
											seq.from = feat.locations[0].from.to_i
											seq.to = feat.locations[0].to.to_i
											seq.locus = gb.accession
											seq.source = type.to_s
											seq.sequence = gb.seq.subseq(seq.from, seq.to)
											seq.trans_table = taxon.trans_table
											seq.references = ref
											seq.division = gb.division
											is << seq
											fa += 1
										end
									end
									
									if seq
										# select better description if exists.
										if h['product']
											seq.description = h['product'][0]
										elsif h['note']
											seq.description = h['note'][0]
										else
											seq.description = "" if ! seq.description
										end
										
										# select better id if exists.
										if h['protein_id']
											id = gb.accession + "|" + h['protein_id'][0]
											seq.subid = id
											seq.accession = h['protein_id'][0]
										elsif h['locus_tag']
											id = gb.accession + "|" + h['locus_tag'][0]
											seq.subid = id
											seq.accession = h['locus_tag'][0]
										end
										
										seq.type = "CDS"
										seq.pseudogene = 1 if h['pseudo']
										if h['transl_table']
											seq.trans_table = h['transl_table'][0]
										end
										seq.translation = h['translation'][0] if h['translation']
									else
										warn "++++++++++ ERROR MAPING <CDS> TO <gene> OR CREATING <gene> IN LOCUS: " + gb.accession
										next
									end
								else
								end
							elsif type == :nucest
								if feat.feature == "source"
									id = gb.accession
									
									seq = Isolate::Seq.new(id)
									seq.subid = id
									seq.accession = id
									seq.strand = feat.locations[0].strand.to_i
									seq.from = feat.locations[0].from.to_i
									seq.to = feat.locations[0].to.to_i
									seq.locus = gb.accession
									seq.source = type.to_s
									seq.type = "EST"
									seq.description = "EST"
									seq.sequence = gb.seq.subseq(seq.from, seq.to)
									seq.trans_table = taxon.trans_table
									seq.references = ref
									seq.division = gb.division
									is << seq
								end
							end
						end
					else
						skip.puts gb.accession + "\t" + gb.division + "\t" + gb.length.to_s + "\t" + why + "\t" + isolate.to_s + "\t" + strain.to_s + "\t" + country.to_s + "\t" + clone.to_s + "\t" + organelle.to_s
					end
				end
				skip.close
				pass.close
				
			end
			# Write existing features.
			File.open(config.dir_source + taxon.name + "features.txt", "w") do |fo|
				feats.uniq.each do |u|
					fo.puts u
				end
			end
			# Write accepted sequences.
			File.open(config.dir_source + taxon.name + "accepted.txt", "w") do |fo|
				fo.puts "Accession\tLOCUS\tDivision\tSource\tLength"
				is.each_value do |seq|
					fo.puts seq.accession + "\t" + seq.locus + "\t" + seq.division + "\t" + seq.source + "\t" + seq.sequence.length.to_s
				end
			end
			is.locus = chrs
			is.auto_clean
			is
		end
		
		private
		
		def _check_in_source(entry, what)
			entry.features.each do |feat|
				if feat.feature == "source"
					h = feat.to_hash
					return h[what]
				end
			end
		end
		
		def _filter_entry(entry)
			ok = true
			why = []
			if entry.definition.match(/complete genome/)
				ok = false
				why << "complete genome"
			end
			
			if entry.definition.match(/chromosome/)
				ok = false
				why << "chromosome"
			end
			
			if entry.keywords
				if entry.keywords[0] == "WGS"
					ok = false
					why << "WGS"
				end
			end
						
			[ok, why.join("|")]
		end
	end

	class Refseq < Common
		
		def initialize(taxon, options = {:config => nil})
			super
			
			@file = config.dir_source + taxon.name + (taxon.name + ".gb")
		end

		def parse
			genome = Genome::Set.new(taxon, options = {:empty => true})

			warn "* processing Genbank file: " + file
			p = Bio::GenBank.open(file)

			chr = {}
			genome.chromosome = chr
			p.each_entry do |gb|
				next if gb.accession == ""
				
				refs = gb.references
				ref = []
				refs.each do |r|
					ref << r.pubmed if r.pubmed != ""
				end
				ref = ref.join(";")
				
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
							gene.trans_table = taxon.trans_table
							gene.references = ref
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
			genome.auto_clean
			genome
		end
	end
	
	class Broad < Common
		attr_reader :gff_file, :annot_file
		
		def initialize(taxon, options = {:config => nil})
			super
			
			@file = config.dir_source + taxon.name + (taxon.name + ".gb")
			@gff_file = config.dir_source + taxon.name + (taxon.name + ".gff")
			@annot_file = config.dir_source + taxon.name + (taxon.name + ".txt")
		end

		def parse
			puts "* file: " + file
			puts "* gff_file: " + gff_file
			puts "* annotation_file: " + annot_file
			
			genome = Genome::Set.new(taxon, options = {:empty => true})
			
			puts "* reading genbank file"
			p1 = Bio::GenBank.open(file)
			
			chrs = {}
			map = {}
#			refs = {}
			p1.each_entry do |gb|
				next if gb.accession == ""
				
				# Currently no references in these files.
#				ref = []
#				gb.references.each do |r|
#					puts r.pubmed if r.pubmed != ""
#				end
				
#				refs[gb.accession] = ref.join(";")
				chrs[gb.accession] = gb.seq
				id = gb.definition
				if id.match(/(supercont.+?) /)
					id = id.match(/(supercont.+?) /)[0].strip
					map[id] = gb.accession
				else
					map[gb.accession] = gb.accession
				end
			end
			puts "* subpercontigs: " + chrs.length.to_s
			
			puts "* reading GFF file"
			p2 = Bio::GFF.new(File.open(gff_file, "r"))
			p2.records.each do |record|
				if record.feature == "exon"
					# skip aberrant features.
					next if record.start.to_i == record.end.to_i
					
					chr = record.seqname
					chr.sub!(/(supercont1..+?)\%.+/, '\1')
					chr = map[chr]
					
					attr = _parse_attributes(record.attributes)
					
					gene = genome.get_gene_by_acc(attr[:id])
					if gene.nil?
						gene = Genome::Gene.new(attr[:id])
						gene.chromosome = chr
						gene.source = "broad"
						gene.strand = _get_strand(record.strand).to_i
						gene.description = attr[:desc]
						gene.pseudogene = attr[:pseudo]
						gene.type = "CDS"
						gene.trans_table = taxon.trans_table
#						gene.references = refs[map[chr]]
						genome << gene
					end
					exon = Genome::Exon.new(gene.length + 1)
					exon.strand = _get_strand(record.strand).to_i
					exon.from = record.start.to_i
					exon.to = record.end.to_i
					gene << exon
				end
			end
			
			puts "* reading annotation file"
			f = File.open(annot_file, "r")
			f.each_line do |line|
				next if line.match(/^LOCUS/)
				id, symbol, synonim, length, start, stop, strand, name, chr, annot = line.split(/\t/)
				gene = genome.get_gene_by_acc(id)
				if gene.nil?
					raise "WTF: I cannot find the damn gene!"
				end
				gene.description = name
				gene.strand = _get_strand(strand)
				gene.from = start.to_i
				gene.to = stop.to_i
				gene.sequence = chrs[gene.chromosome].subseq(gene.from, gene.to)
			end
			f.close
			
			genome.chromosome = chrs
			genome.auto_clean
			genome
		end
		
		private
		
		def _parse_attributes(c)
			f = _array2hash(c)
			h = {
				:id => f["gene_id"].gsub!(/\"/, "")
			}
			h
		end

		def _array2hash(a)
			h = {}
			a.each do |val|
				h[val[0]] = val[1]
			end
			h
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
			
			genome = Genome::Set.new(taxon, options = {:empty => true})

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
					gene.trans_table = taxon.trans_table
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
			genome.auto_clean
			genome
		end
		
		private

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
	
	class Nelson < Common
		## TODO: This class is actually a bunch of hacks to get the statistics. It has to be properly written.
		attr_reader :ortholog
		def initialize(taxon, ortholog, options  = {:config => nil})
			@ortholog = ortholog
			super(taxon, options = {:config => options[:config]})
			case taxon.type
			when 'spp'
				file = config.dir_result + "genome/sequence" + ortholog.name + (taxon.name + "-" + ortholog.name + ".txt")
			when 'clade'
				file = config.dir_result + "isolate/sequence" + ortholog.name + (taxon.name + "-" + ortholog.name + ".txt")
			end
			if file.exist?
				_read_sequence(file)
			end
		end
		
		def _read_sequence(file)
			head = []
			data = {}
			n = 0
			File.new(file, "r").each do |line|
				if line =~ /SEQUENCE/
					head = line.split("\t")
					head.each {|h| data[h] = ""}
				else
					n += 1
					tmp = line.split("\t")
					tmp.each_index do |i|
						data[head[i]] = tmp[i]
					end
					#puts data["SEQUENCE"] + "\t" + data["sequence"].length.to_s + "\t" + data["cds"].length.to_s + "\t" + data["translation"].length.to_s
				end
			end
			puts ortholog.name + "\t" + taxon.name + "\t" + n.to_s
		end
	end
end
