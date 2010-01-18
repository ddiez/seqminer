require 'Item'
require 'SeqMiner'
require 'Parser'

require 'progressbar'
require 'net/ftp'
require 'net/http'

module Download
	include Item
	
	class Common
		# This method downloads a file using the FTP protocol.
		# Parametes:
		# * host: Host name.
		# * dir: Directory in the server.
		# * file: File to download
		# * ofile: File to save the download.
		def ftp_download(host, dir, file, ofile)
			ftp = Net::FTP.new(host)
			ftp.login
			ftp.chdir(dir)
					
			filesize = ftp.size(file)
			transferred = 0
			pb = ProgressBar.new(file, 100)
			ftp.getbinaryfile(file, ofile, 1024) do |data|
				transferred += data.size
				if transferred != 0
					percent_finished = 100 * (transferred.to_f / filesize.to_f)
					pb.set(percent_finished)
				end
			end
			pb.finish
			ftp.close
		end
		
		# This method downloads a file using the HTTP protocol.
		# Parametes:
		# * host: Host name.
		# * dir: Directory in the server.
		# * file: File to download
		# * ofile: File to save the download.
		def http_download(host, dir, file, ofile)
			puts "* host: " + host
			puts "* dir: " + dir
			puts "* file: " + file
			puts "* ofile: " + ofile
			
			http = Net::HTTP.start(host)
			req = Net::HTTP::Get.new("/" + dir + "/" + file)
			transferred = 0
			http.request(req) do |resp|
				pb = ProgressBar.new(file, 100)
				filesize = resp.content_length
				f = File.open(ofile, 'w')
				resp.read_body do |data|
					transferred += data.size
					if(transferred != 0)
						percent_finished = 100 * (transferred.to_f / filesize.to_f)
						pb.set(percent_finished)
					end
					f.write(data)
				end
				f.close
				pb.finish
			end
		end
		
		# This method downloads a file using NCBI Eutils.
		# Currently leverages the job to the Bioperl NCBI API since I couldn't find a way to mimic the output with
		# Bioruby.
		# Parametes:
		# * term: Term to search.
		# * db: Database to search.
		# * ofile: File to save the download.
		def ncbi_download(term, db, ofile)
			Bio::NCBI.default_email = "diez@kuicr.kyoto-u.ac.jp"
			ncbi = Bio::NCBI::REST.new
			
			system("./ncbi_download.pl \"#{term}\" #{db} #{ofile}")
			
			# TODO: how to do it in ruby??
			#gpid = ncbi.esearch(term, {:db => "nuccore", :rettype => "gb", :retmode => "txt", :usehistory => 'y'})
			#puts gpid.length

			#gpid.each do |gid|
				#of = File.new(outfile, "a")
				#genome = ncbi.efetch(gid, {"db"=>"genome", "rettype"=>"gbwithparts", "retmode" => "txt"})
				#of.puts genome
				#of.close
			#end
			#refseq_process_source(outfile)
		end
	end

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

	class Download < Common
		attr_accessor :taxon
		attr_reader :id, :config
		
		# Config here is required and inherited from the Set.
		def initialize(id, config)
			@id = id
			#super(id)
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
				download_eupathdb('plasmodb')
			when "tritrypdb"
				download_eupathdb('tritrypdb')
			when "giardiadb"
				download_eupathdb('giardiadb')
			when "broad"
				download_broad
			when "ncbi"
				download_ncbi
			end
		end

		def download_clade
			puts "* downloading clade (nuccore) " + id
			download_nuccore
			puts "* downloading clade (nucest) " + id
			download_nucest
		end

		def download_nuccore
			outdir = config.dir_source + taxon.name
			outdir.mkpath if ! outdir.exist?
			outfile = outdir + (taxon.name + "_nuccore.gb")
			outfile.unlink if outfile.exist?
			
			term = "txid" + taxon.id + "[Organism:exp]"
			
			ncbi_download(term, "nuccore", outfile)
		end

		def download_nucest
			outdir = config.dir_source + taxon.name
			outdir.mkpath if ! outdir.exist?
			outfile = outdir + (taxon.name + "_nucest.gb")
			outfile.unlink if outfile.exist?
			
			term = "txid" + taxon.id + "[Organism:exp]"
			
			ncbi_download(term, "nucest", outfile)
		end

		def download_broad
			# TODO: not implemented.
		end
		
		def download_eupathdb(db)
			host = {
				'plasmodb' =>  'plasmodb.org',
				'giardiadb' => 'giardiadb.org',
				'tritrypdb' => 'tritrypdb.org'
			}
			
			current_release = {
				'plasmodb' =>  '6.3',
				'giardiadb' => '2.1',
				'tritrypdb' => '2.0'
			}
			
			release = current_release[db]
			
			# Build dir/file/outdir/outfile, includes hacks to deal with file/directory structure inconsistencies.
			dir = Pathname("common/downloads")
			
			outdir = config.dir_source + taxon.name
			outdir.mkpath if ! outdir.exist?
			outfile = config.dir_source + taxon.name + (taxon.name + ".gff")
			
			case db
			when 'plasmodb'
				dir =  dir + ("release-" + release) + taxon.short_name
				file = taxon.short_name + "_PlasmoDB-" + release + ".gff"
			when 'giardiadb'
				dir =  dir + ("release-" + release) + taxon.short_name
				if taxon.name == "giardia.lamblia_ATCC_50803"
					dir = "common/downloads/release-" + release + "/" + "GintestinalisAssemblageA"
				end
				file = taxon.short_name + "_GiardiaDB-" + release + ".gff"
			when 'tritrypdb'
				dir =  dir + ("release-" + release) + taxon.short_name
				file = taxon.short_name + "_TriTrypDB-" + release + ".gff"
					
				if taxon.name.match(/trypanosoma.brucei/)
					file = taxon.short_name + taxon.strain.capitalize + "_TriTrypDB-" + release + ".gff"
				end
				
				if taxon.name.match(/leishmania.major_Friedlin/)
					if release == "1.3"
						file = taxon.short_name + "_TriTryDB-" + release + ".gff"
					end				
				end
				
				if taxon.name == "trypanosoma.cruzi_CL_Brener"
					file = taxon.short_name + "Esmeraldo" + "_TriTrypDB-" + release + ".gff"
					outfile = config.dir_source + taxon.name + (taxon.name + "-Esmeraldo" +  ".gff")
				end
			end	

			http_download(host[db], dir, file, outfile)
			
			if taxon.name == "trypanosoma.cruzi_CL_Brener"
				file = taxon.short_name + "NonEsmeraldo" + "_TriTrypDB-" + release + ".gff"
				outfile = config.dir_source + taxon.name + (taxon.name + "-NonEsmeraldo" +  ".gff")
				http_download(host[db], dir, file, outfile)
			end
		end

		# Methods to download Genome sequences from NCBI (usually RefSeq).
		def download_ncbi
			db = "genome"
			term = "txid" + taxon.id
			
			if taxon.name == "babesia.bovis_T2Bo"
				term += "[Organism:exp]+biomol genomic[properties]"
				db = "nuccore"
			end
			
			if taxon.name == "plasmodium.falciparum_dd2"
				term += "[Organism:exp]+biomol genomic[properties]"
				db = "nuccore"
			end
			
			if taxon.name == "plasmodium.falciparum_hb3"
				term += "[Organism:exp]+biomol genomic[properties]"
				db = "nuccore"
			end
			
			outdir = config.dir_source + taxon.name
			outdir.mkpath if ! outdir.exist?
			outfile = config.dir_source + taxon.name + (taxon.name + ".gb")
			outfile.unlink if outfile.exist?
			
			ncbi_download(term, db, outfile)
		end

		def eupathdb_process_source(infile)
			p = Parser::Eupathdb.new(infile, taxon.name, options = {:config => config})
			g = p.parse

			outdir = config.dir_sequence + taxon.name
			outdir.mkpath if ! outdir.exist?

			g.write_fasta('gene', outdir + "gene.fa")
			g.write_fasta('cds', outdir + "cds.fa")
			g.write_fasta('protein', outdir + "protein.fa")
			g.write_fasta('6frame', outdir + "6frame.fa")
			g.write_fasta('genome', outdir + "genome.fa")
			g.write_gff(outdir + "genome.gff")
		end
		
		def refseq_process_source(infile)
			p = Parser::Refseq.new(infile, taxon.name, option = {:config => config})
			g = p.parse
			
			outdir = config.dir_sequence + taxon.name
			outdir.mkpath if ! outdir.exist?

			g.write_fasta('gene', outdir + "gene.fa")
			g.write_fasta('cds', outdir + "cds.fa")
			g.write_fasta('protein', outdir + "protein.fa")
			g.write_fasta('6frame', outdir + "6frame.fa")
			g.write_fasta('genome', outdir + "genome.fa")
			g.write_gff(outdir + "genome.gff")
		end

		def debug
			puts "* download id: " + id
		end
	end

	class Pfam < Common
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

		def update
			# TODO: check there are updates to download?
			
			# Check directory exists.
			dir_pfam = config.dir_pfam + release
			if ! dir_pfam.exist?
				dir_pfam.mkpath
				config.dir_pfam_current.make_symlink(dir_pfam)
			end
			
			# Download files (with progress bar).
			files.each do |file|
				ftp_download(host, base_dir + release, file, dir_pfam + file)
			end
		end
	end
end
