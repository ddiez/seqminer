# SeqMiner is a tool for mining sequence information. It aims to
# help detect sequences belonging to specific protein families.
#
# Author::    Diego Diez  (mailto:diez@kuicr.kyoto-u.ac.jp)
# Copyright:: Copyright (c) 2010
# License::   Distributes under the same terms as Ruby

require 'item'
require 'config'
require 'parser'

require 'progressbar'
require 'net/ftp'
require 'net/http'

module Download
	include Item
	
	class Base
		include Common
		# This method downloads a file using the FTP protocol.
		# Parameters:
		# host: Host name.
		# dir:: Directory in the server.
		# file:: File to download
		# ofile:: File to save the download.
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
		# Parameters:
		# host:: Host name.
		# dir:: Directory in the server.
		# file:: File to download
		# ofile:: File to save the download.
		def http_download(host, dir, file, ofile)
			puts "* host: " + host
			puts "* dir: " + dir
			puts "* file: " + file
			puts "* ofile: " + ofile
			
			http = Net::HTTP.start(host)
			req = Net::HTTP::Get.new("/" + dir + "/" + file)
			transferred = 0
			http.request(req) do |resp|
				filesize = resp.content_length
				
				if _check_download(ofile, filesize, "size")
					pb = ProgressBar.new(file, 100)
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
				else
					break
				end
			end
		end
		
		# This method downloads a file using NCBI Eutils.
		# Bioruby.
		# Parameters:
		# term:: Term to search.
		# db:: Database to search.
		# ofile:: File to save the download.
		def ncbi_download(term, db, ofile)
			#puts "* host: " + host
			#puts "* dir: " + dir
			puts "* db: " + db
			puts "* term: " + term
			puts "* ofile: " + ofile
			Bio::NCBI.default_email = "vardb@kuicr.kyoto-u.ac.jp"
			ncbi = Bio::NCBI::REST.new
			rid = ncbi.esearch(term, {:db => db}, limit = 0)
			
			puts "* n: " + rid.length.to_s
				
			if rid.length > 0
				if _check_download(ofile, rid.length, "gb")
					retmax = 500
					retstart = 0
					
					transferred = 0
					pb = ProgressBar.new(ofile.basename.to_s, 100)
					#ret = 0
					out = File.open(ofile, "w")
					while(retstart < rid.length)
						rtmp = rid[retstart,retmax]
						res = ncbi.efetch(rtmp, {:db => db, :rettype => "gbwithparts", :retmode => "txt"})
							
						if res.empty?
							warn "[ERROR] data returned by server is empty!".bold.on_red.white
							return
						end
						# TODO: add server ERROR check (like Perl script)
						out.puts res
						transferred += rtmp.length
						if(transferred != 0)
							percent_finished = 100 * (transferred.to_f / rid.length.to_f)
							#puts percent_finished
							pb.set(percent_finished.to_i)
						end
						retstart += retmax
					end
					out.close
					puts
				end
			end
			# Old method. Just uncomment (and comment out the code above) to revert to it.
#			res = system("./ncbi_download.pl \"#{term}\" #{db} #{ofile}")
#			_check_result(res)
		end
	end

	class Set < Set
		attr_reader :config
		def initialize(ts = nil, options = {:empty => false, :config => nil})
			super()

			if ! options[:config]
				@config = Config::General.new
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

	class Download < Base
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
			#outfile.unlink if outfile.exist?
			
			term = "txid" + taxon.id + "[Organism:exp]"
			
			ncbi_download(term, "nuccore", outfile)
		end

		def download_nucest
			outdir = config.dir_source + taxon.name
			outdir.mkpath if ! outdir.exist?
			outfile = outdir + (taxon.name + "_nucest.gb")
			#outfile.unlink if outfile.exist?
			
			term = "txid" + taxon.id + "[Organism:exp]"
			
			ncbi_download(term, "nucest", outfile)
		end

		def download_broad
			download_ncbi
			
			return
			# TODO: finish and test.
			# this are hacks for each species.
			if taxon.name == "plasmodium.falciparum_dd2"
				outdir = config.dir_source + taxon.name
				
				host = "www.broadinstitute.org"
				dir = "annotation/genome/plasmodium_falciparum_spp/download/"
				
				# gtf file.
				file = "?sp=EATranscriptsGtf&sp=SPF_DD2_V1&sp=S.zip"
				outfile = config.dir_source + taxon.name + (taxon.name + ".gff")
				# TODO: unzip and rename.
				
				
				http_download(host, dir, file, outfile)
				
				# pfam2gene file.
				file = "?sp=EAProteinFamilytoGenes&sp=SPF_DD2_V1&sp=S.zip"
				outfile = config.dir_source + taxon.name + (taxon.name + ".txt")
				
				http_download(host, dir, file, outfile)
			end
			
			if taxon.name == "plasmodium.falciparum_hb3"
				outdir = config.dir_source + taxon.name
								
				host = "www.broadinstitute.org"
				dir = "annotation/genome/plasmodium_falciparum_spp/download/"
				
				# gtf file.
				file = "?sp=EATranscriptsGtf&sp=SPF_HB3_V1&sp=S.zip"
				outfile = config.dir_source + taxon.name + (taxon.name + ".zip")
				
				http_download(host, dir, file, outfile)

				# pfam2gene file.
				file = "?sp=EAProteinFamilytoGenes&sp=SPF_DD2_V1&sp=S.zip"
				outfile = config.dir_source + taxon.name + (taxon.name + ".zip")
				
				http_download(host, dir, file, outfile)
			end
		end
		
		def download_eupathdb(db)
			#host = {
			#	'plasmodb' =>  'plasmodb.org',
			#	'giardiadb' => 'giardiadb.org',
			#	'tritrypdb' => 'tritrypdb.org'
			#}
			
			#current_release = {
			#	'plasmodb' =>  '7.2',
			#	'giardiadb' => '2.3',
			#	'tritrypdb' => '3.1'
			#}
			host = config.db_host
			current_release = config.db_release
			
			release = current_release[db]
			
			# Build dir/file/outdir/outfile, includes hacks to deal with file/directory structure inconsistencies.
			dir = Pathname("common/downloads")
			
			outdir = config.dir_source + taxon.name
			outdir.mkpath if ! outdir.exist?
			outfile = config.dir_source + taxon.name + (taxon.name + ".gff")
			
			case db
			when 'plasmodb'
				dir =  dir + ("release-" + release) + taxon.short_name + "gff/data"
				
				# hack to fix repository inconsistencies.
				if taxon.name.match(/vivax/)
					dir =  Pathname("common/downloads") + ("release-" + release) + taxon.short_name + "gff"
				end
				
				# hack to fix repository inconsistencies.
				if taxon.name.match(/yoelii/)
					dir =  Pathname("common/downloads") + ("release-" + release) + taxon.short_name + "gff"
				end
				
				file = taxon.short_name + "_PlasmoDB-" + release + ".gff"
			when 'giardiadb'
				dir =  dir + ("release-" + release) + taxon.short_name + "gff"
				if taxon.name == "giardia.lamblia_ATCC_50803"
					dir = Pathname("common/downloads") + ("release-" + release) + "GintestinalisAssemblageA" + "gff"
				end
				file = taxon.short_name + "_GiardiaDB-" + release + ".gff"
			when 'tritrypdb'
				dir =  dir + ("release-" + release) + taxon.short_name + "gff"
				file = taxon.short_name + "_TriTrypDB-" + release + ".gff"
					
				if taxon.name.match(/trypanosoma.brucei/)
					file = taxon.short_name + taxon.strain.capitalize + "_TriTrypDB-" + release + ".gff"
				end
				
				if taxon.name.match(/leishmania.major_Friedlin/)
					file = taxon.short_name + "Friedlin_TriTrypDB-" + release + ".gff"
					if release == "1.3"
						file = taxon.short_name + "_TriTryDB-" + release + ".gff"
					end				
				end
				
				if taxon.name == "trypanosoma.cruzi_CL_Brener"
					file = taxon.short_name + "Esmeraldo-Like" + "_TriTrypDB-" + release + ".gff"
					outfile = config.dir_source + taxon.name + (taxon.name + "-Esmeraldo" +  ".gff")
				end
			end	

			http_download(host[db], dir, file, outfile)
			
			# Extra download.
			if taxon.name == "trypanosoma.cruzi_CL_Brener"
				file = taxon.short_name + "NonEsmeraldo-Like" + "_TriTrypDB-" + release + ".gff"
				outfile = config.dir_source + taxon.name + (taxon.name + "-NonEsmeraldo" +  ".gff")
				http_download(host[db], dir, file, outfile)
			end
		end

		# Methods to download Genome sequences from NCBI (usually RefSeq).
		def download_ncbi
			db = "genome"
			term = "txid" + taxon.id
						
			# WGS projects must be downloaded this way:
			
			if taxon.name == "borrelia.burgdorferi_80a"
				term += "[Organism:exp]+biomol genomic[properties]"
				db = "nuccore"
			end
			
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
			#outfile.unlink if outfile.exist?
			
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

	class Pfam < Base
		attr_accessor :host, :base_dir, :release, :dir, :files
		attr_reader :config

		def initialize(options = {:config => nil})
			@host = 'ftp.sanger.ac.uk'
			@base_dir = '/pub/databases/Pfam/releases/'
			@release = 'Pfam25.0'
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
				@config = Config::General.new
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
