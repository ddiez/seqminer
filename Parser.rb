require 'bio'
require 'uri'
require 'Genome'
require 'Isolate'

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
			is = Isolate::Set.new(name, options = {:empty => true})
			
			files.each_pair do |type, file|
				next if ! file.exist?
				warn "* processing Genbank [" + type.to_s + "] file: " + file
				p = Bio::GenBank.open(file)
				
				skip = File.new(config.dir_source + taxon.name + (type.to_s + "_skip.txt"), "w")
				pass = File.new(config.dir_source + taxon.name + (type.to_s + "_pass.txt"), "w")
				size = File.new(config.dir_source + taxon.name + (type.to_s + "_size.txt"), "w")
				iso = File.new(config.dir_source + taxon.name + (type.to_s + "_isolate.txt"), "w")
				str = File.new(config.dir_source + taxon.name + (type.to_s + "_strain.txt"), "w")
				con = File.new(config.dir_source + taxon.name + (type.to_s + "_country.txt"), "w")
				clo = File.new(config.dir_source + taxon.name + (type.to_s + "_clone.txt"), "w")
				notype = File.new(config.dir_source + taxon.name + (type.to_s + "_notype.txt"), "w")
				susp = File.new(config.dir_source + taxon.name + (type.to_s + "_susp.txt"), "w")
				
				skip.puts "Accession\tLength\tWhy\tIsolate\tStrain\tCountry\tClone"
				pass.puts "Accession\tLength\tIsolate\tStrain\tCountry\tClone"
				iso.puts "Accession\tLength\tIsolate"
				str.puts "Accession\tLength\tStrain"
				con.puts "Accession\tLength\tCountry"
				clo.puts "Accession\tLength\tClone"
				notype.puts "Accession\tLength"
				susp.puts "Accession\tLength\tLocus\tIsolate\tStrain\tCountry\tClone"
				feats = []
				p.each_entry do |gb|
					#warn "* processing: " + gb.accession
					size.puts gb.accession + "\t" + gb.length.to_s
					strain = _check_in_source(gb, "strain")
					isolate = _check_in_source(gb, "isolate")
					country = _check_in_source(gb, "country")
					clone = _check_in_source(gb, "clone")

					ok, why = _filter_entry(gb)
					if ok
						pass.puts gb.accession + "\t" + gb.length.to_s + "\t" + isolate.to_s + "\t" + strain.to_s + "\t" + country.to_s + "\t" + clone.to_s
						if isolate
							iso.puts gb.accession + "\t" + gb.length.to_s + "\t" + isolate.to_s
						elsif strain
							str.puts gb.accession + "\t" + gb.length.to_s + "\t" + strain.to_s
						elsif country
							con.puts gb.accession + "\t" + gb.length.to_s + "\t" + country.to_s
						elsif clone
							clo.puts gb.accession + "\t" + gb.length.to_s + "\t" + clone.to_s
						else
							notype.puts gb.accession + "\t" + gb.length.to_s
						end
						fa = 0
						gb.features.each do |feat|
							feats << feat.feature
							if type == :nuccore
								if feat.feature == "gene"
									h = feat.to_hash
									
									id = nil
									acc = ""
									if h['locus_tag']
										id = gb.accession + "|" + h['locus_tag'][0]
										acc = h['locus_tag'][0]
										susp.puts gb.accession + "\t" + gb.length.to_s + "\t" + id + "\t" + isolate.to_s + "\t" + strain.to_s + "\t" + country.to_s + "\t" + clone.to_s
									elsif h['gene']
										id = gb.accession + "|" + h['gene'][0]
										acc = h['gene'][0]
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
									if h['note']
										seq.description = h['note'][0]
									else
										seq.description = ""
									end
									seq.type = "gene"
									seq.pseudogene = 1 if h['pseudo']
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
											seq.type = "CDS"
											is << seq
											fa += 1
										else
											id = gb.accession + "-" + (fa + 1).to_s
											
											seq = Isolate::Seq.new(id)
											seq.subid = ""
											seq.accession = ""
											seq.strand = feat.locations[0].strand.to_i
											seq.from = feat.locations[0].from.to_i
											seq.to = feat.locations[0].to.to_i
											seq.locus = gb.accession
											seq.source = type.to_s
											seq.type = "CDS"
											is << seq
											fa += 1
										end
									end
									
									if seq
										if h['product']
											seq.description = h['product'][0]
										elsif h['note']
											seq.description = h['note'][0]
										else
											seq.description = "" if ! seq.description
										end
										
										seq.pseudogene = 1 if h['pseudo']
										seq.trans_table = h['trans_table'][0] if h['trans_table']
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
									is << seq
								end
							end
						end
					else
						skip.puts gb.accession + "\t" + gb.length.to_s + "\t" + why + "\t" + isolate.to_s + "\t" + strain.to_s + "\t" + country.to_s + "\t" + clone.to_s 
					end
				end
				skip.close
				size.close
				pass.close
				iso.close
				str.close
				con.close
				clo.close
				notype.close
				susp.close
				feats.uniq.each do |u|
					warn u
				end
			end
			fo = File.open(config.dir_source + taxon.name + "accepted.txt", "w")
				is.each_value do |seq|
				fo.puts seq.locus + "\t" + seq.accession + "\t" + seq.source
			end
			fo.close
			
			is
		end
		
		def _check_in_source(entry, what)
			tmp = nil
			entry.features.each do |feat|
				if feat.feature == "source"
					h = feat.to_hash
					tmp = h[what]
					break
				end
			end
			tmp
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
			
			genome = Genome::Set.new(name, options = {:empty => true})
			
			puts "* reading genbank file"
			p1 = Bio::GenBank.open(file)
			
			chrs = {}
			map = {}
			p1.each_entry do |gb|
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
			
			genome
		end
		
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
