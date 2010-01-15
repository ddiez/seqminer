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
				d.execute
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
				download_clade
			end
		end

		def download_spp
			puts "* downloading spp " + id
			case taxon.source
			when "plasmodb"
				#download_plasmodb
			when "tritrypdb"
				#download_tritrypdb
			when "ncbi"
				download_refseq
			end
		end

		def download_clade
			#puts "* downloading clade " + id
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

			http_download(host, dir, file, outfile)
			eupathdb_process_source(outfile)
		end

		def download_refseq
			Bio::NCBI.default_email = "diez@kuicr.kyoto-u.ac.jp"
			ncbi = Bio::NCBI::REST.new

			outdir = config.dir_source + taxon.name
			outdir.mkpath if ! outdir.exist?
			outfile = config.dir_source + taxon.name + (taxon.name + ".gb")
			outfile.unlink if outfile.exist?

			term = "txid" + taxon.id
			gpid = ncbi.esearch(term, {:db => "genome", :rettype => "gb", :retmode => "txt"})
			gpid.each do |gid|
				of = File.new(outfile, "a")
				genome = ncbi.efetch(gid, {"db"=>"genome", "rettype"=>"gbwithparts", "retmode" => "txt"})
				of.puts genome
				of.close
			end
			refseq_process_source
		end

		def http_download(host, dir, file, outfile)
			Net::HTTP.start(host) do |http|
				req = Net::HTTP::Get.new("/" + dir + "/" + file)
				transferred = 0
				http.request(req) do |resp|
					pb = ProgressBar.new(file, 100)
					filesize = resp.content_length
					File.open(outfile, 'w') do |f|
						resp.read_body do |data|
							transferred += data.size
							if(transferred != 0)
								percent_finished = 100 * (transferred.to_f / filesize.to_f)
								pb.set(percent_finished)
							end
							f.write(data)
						end
					end
					pb.finish
				end
			end
		end

		def eupathdb_process_source(infile)
			p = Parser::Eupathdb.new(infile, taxon.name, options = {:config => config})
			g = p.parse

			outdir = config.dir_sequence + taxon.name
			outdir.mkpath if ! outdir.exist?

			g.write_fasta('gene', outdir + "gene.fa")
			g.write_fasta('cds', outdir + "cds.fa")
			g.write_fasta('protein', outdir + "protein.fa")
			#g.write_fasta('genome')
			#g.write_gff
		end
		
		def refseq_process_source(infile)
			p = Parser::Refseq.new(infile, taxon.name, option = {:config => config})
			g = p.parse
			
			outdir = config.dir_sequence + taxon.name
			outdir.mkpath if ! outdir.exist?

			g.write_fasta('gene', outdir + "gene.fa")
			g.write_fasta('cds', outdir + "cds.fa")
			g.write_fasta('protein', outdir + "protein.fa")
			#g.write_fasta('genome')
			#g.write_gff
		end

		def debug
			puts "* download id: " + id
		end
	end

	class Pfam
		require 'net/ftp'

		attr_accessor :host, :base_dir, :release, :dir, :files
		attr_reader :config

		def initialize(options = {:config => nil})
			@host = 'ftp.sanger.ac.uk'
			@base_dir = '/pub/databases/Pfam/releases/'
			@release = 'Pfam24.0'
			@files = [
				'Pfam-A.seed.gz',
				'Pfam-A.full.gz',
				'Pfam-A.hmm.gz',
				'Pfam-B.gz',
				'relnotes.txt',
				'userman.txt'
			]

			if options[:config]
				@config = options[:config]
			else
				@config = SeqMiner::Config.new
			end
		end

		# Runs un update job to get the Pfam version specified.
		# TODO: check Pfam version.
		def update
			ftp = Net::FTP.new(host)
			ftp.login
			ftp.chdir(base_dir + "/" + release)
			
			# Check directory exists.
			dir_pfam = config.dir_pfam + release
			dir_pfam.mkpath if ! dir_pfam.exist?
			
			# Download files (with progress bar).
			files.each do |file|
				filesize = ftp.size(file)
				transferred = 0
				pb = ProgressBar.new(file, 100)
				ftp.getbinaryfile(file, dir_pfam + file, 1024) do |data|
					transferred += data.size
					if transferred != 0
						percent_finished = 100 * (transferred.to_f / filesize.to_f)
						pb.set(percent_finished)
					end
				end
				pb.finish
			end
			ftp.close

			# Gunzip files.
			files.each do |file|
				if file.match(/.gz$/)
					outfile = dir_pfam + file
					system("gunzip #{outfile}")
				end
			end
			
			# Press hmm files.
			system("hmmpress #{dir_pfam}/Pfam-A.hmm")
		end
	end
end