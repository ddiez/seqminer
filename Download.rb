require 'Item'
require 'SeqMiner'
require 'progressbar'
require 'net/http'
require 'Parser'

module Download
	include Item

	class Set < Set
		attr_reader :config

		def initialize(ts = nil, options = {:empty => false, :config => nil})
			super()

			if ! options[:config]
				@config = SeqMiner::Config.new
			else
				@config = options[:config]
			end


			if ! options[:empty]
				if ts.nil?
					ts = Taxon::Set.new(options = {:config => config})
				end
				ts.each_value do |taxon|
					d = Download.new(taxon.name + "." + taxon.type, config)
					d.taxon = taxon
					add(d)
				end
			end
		end

		def download
			each_value do |d|
				d.execute if d.taxon.type == "spp"
			end
		end
	end

	class Download < Item
		attr_accessor :taxon
		attr_reader :config

		# Config here is required and inherited from the Set.
		def initialize(id, config)
			super(id)
			@config = config
		end

		def execute
			case taxon.type
			when "spp"
				download_spp
			when "clade"
			end
		end
		
		def download_spp
			puts "* downloading spp " + id
			case taxon.source
			when "plasmodb"
				download_plasmodb
			when "tritrypdb"
				download_tritrypdb
			when "ncbi"
				download_refseq
			end
		end
		
		def download_clade
			puts "* downloading clade " + id
		end
		
		def download_plasmodb			
			release = "6.3"
			host = "plasmodb.org"
			dir = "common/downloads/release-" + release + "/" + taxon.short_name
			file = taxon.short_name + "_PlasmoDB-" + release + ".gff"
			
			outdir = config.dir_source + taxon.name
			outdir.mkpath if ! outdir.exist?
			#outfile = config.dir_source + taxon.name + file
			outfile = config.dir_source + taxon.name + (taxon.name + ".gff")
			
			http_download(host, dir, file, outfile)
			eupathdb_process_source(outfile)
		end
		
		def download_tritrypdb
			release = "2.0"
			host = "tritrypdb.org"
			dir = "common/downloads/release-" + release + "/" + taxon.short_name
			
			if taxon.name.match(/trypanosoma/)
				if taxon.name.match(/cruzi/)
				else
					file = taxon.short_name + taxon.strain.capitalize + "_TriTrypDB-" + release + ".gff"
				end
			else
				file = taxon.short_name + "_TriTrypDB-" + release + ".gff"
			end
			
			outdir = config.dir_source + taxon.name
			outdir.mkpath if ! outdir.exist?
			outfile = config.dir_source + taxon.name + (taxon.name + ".gff")
			
			#http_download(host, dir, file, outfile)
			eupathdb_process_source(outfile)
		end
		
		def download_refseq
			puts "  > downloading from refseq"
			Bio::NCBI.default_email = "diez@kuicr.kyoto-u.ac.jp"
			ncbi = Bio::NCBI::REST.new
			
			#term = taxon.binomial.sub(/\./, " ") + " " + taxon.strain + "[Organism]"
			term = "txid" + taxon.id
			puts "  > search term [taxid]: " + term
			gpid = ncbi.esearch(term, {:db => "genome", :rettype => "gb", :retmode => "txt"})
			gpid.each do |gid|
				puts "  + found " + gid
				#of = File.new("tmp/" + gid + ".gb", "w")
				#genome = ncbi.efetch(gid, {"db"=>"genome", "rettype"=>"gbwithparts", "retmode" => "txt"})
				#of.puts genome
				#of.close
			end
		end
		
		def http_download(host, dir, file, outfile)
			puts "* downloading: " + file
			puts "* host: " + host
			puts "* dir: " + dir
			puts "* file: " + file
			puts "* url: http://" + host + "/" + dir + "/" + file
			puts "* outfile: " + outfile
			Net::HTTP.start(host) do |http|
				#resp = http.get("/" + dir + "/" + file)
				req = Net::HTTP::Get.new("/" + dir + "/" + file)
				alreadyDL = 0
				http.request(req) do |resp|
					pBar = ProgressBar.new(file, 100)
					size = resp.content_length
					File.open(outfile, 'w') do |f|
						resp.read_body do |segment|
							alreadyDL += segment.length
							if(alreadyDL != 0)
								aPercent = (alreadyDL * 100) / size
								pBar.set(aPercent)
							end
							f.write(segment)
						end
					end
					pBar.finish
				end
			end
		end
		
		def eupathdb_process_source(infile)
			p = Parser::Eupathdb.new(infile, config, taxon)
			g = p.parse
#			g.print_fasta('gene')
#			g.print_fasta('nucleotide')
#			g.print_fasta('protein')
#			g.print_fasta('genome')
#			g.print_gff
			
			
		end
		
		def debug
			puts "* download id: " + id
		end
	end
end
