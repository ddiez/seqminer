# SeqMiner is a tool for mining sequence information. It aims to
# help detect sequences belonging to specific protein families.
#
# Author::    Diego Diez  (mailto:diez@kuicr.kyoto-u.ac.jp)
# Copyright:: Copyright (c) 2010
# License::   Distributes under the same terms as Ruby

require 'term/ansicolor'

# This module contains methods common to all other modules. Should be potentially included in all other definitions.

class String
	include Term::ANSIColor
end

module Common
	private
	# Checks the result of a tool and exits if it fails and the argument exitonfail is true (default).
	# It uses term/ansicolor for fancy terminal coloring.
	# === Arguments:
	# res:: result from an execute method
	# exitonfail:: [true, false] controls wheter the funcion should terminate the running process on fail.
	# msg:: Error message to append to error report.
	def _check_result(res, exitonfail = true, msg = "an error has occurred")
		if res
			warn "[DONE]".green.bold
		else
			warn ["[FAIL]", msg].join(" ").blink.red.bold
			exit if exitonfail
		end
	end
	
	# quickly checks the number of sequences in a FASTA file.
	def _check_nseq(file)
		`grep "^>" #{file} | wc -l`.to_i
	end
	
	def _check_nseq_gb(file)
		nl = `grep "^LOCUS" #{file} | wc -l`.to_i
		ne = `grep "^\/\/" #{file} | wc -l`.to_i
		if ne == nl
			return ne
		else
			return -1
		end
	end
	
	def _check_seq_gb(file, rid)
		p = Bio::GenBank.open(file)
		gid = []
		p.each do |e|
			gid << e.gi.gsub("GI:", "")
		end
		
		return gid
	end
	
	def _check_file_size(file)
		File.size(file)
	end
	
	def _check_download_gb(file, rid)
		if File.exists?(file)
			# first, check file corruption:
			res = _check_nseq_gb(file)
			if res == -1
				warn ["[DOWNLOAD]".red.bold, "File was corrupred!- redownloading"].join(" ")
				File.unlink file
				return rid
			end
			
			gid = _check_seq_gb(file, rid)
			puts "* downloaded: " + gid.length.to_s.blue
			rid = rid - gid
			puts "* remaining: " + rid.length.to_s.red
			
			if rid.length == 0
				warn ["[DONE]".green.bold, "Using existing file- skipping"].join(" ")
			else
				warn ["[DOWNLOAD]".red.bold, "Existing file truncated but seems OK- downloading rest of sequences"].join(" ")
			end
		else
			warn ["[DOWNLOAD]".blue.bold, "File does not exist- downloading"].join(" ")
		end
		return rid
	end
	
	def _check_download_size(file, fsize)
		if File.exists?(file)
			s = _check_file_size(file)
			puts "* downloaded: " + s.to_s.blue
			if s != fsize
				warn ["[DOWNLOAD]".red.bold, "File was corrupred!- redownloading"].join(" ")
				File.unlink file
				return true
			else
				warn ["[DONE]".green.bold, "Using existing file- skipping"].join(" ")
				return false
			end
		else
			warn ["[DOWNLOAD]".blue.bold, "File does not exist- downloading"].join(" ")
			return true
		end
	end
	
	# this function check for duplicated entries in GenBank files (same LOCUS, different version and GI)
	# and writes a new file that only uses the latest version of an entry, and writes discarded version
	# into a file.
	def _check_duplicates_gb(file)
		puts "* check duplicates: " + file
		system "./check_duplicates_gb.pl " + file
	end
	
#	def _check_download(file, nt, type)
#		#puts "number of sequences to download: " + nt.to_s
#		# check if file exists.
#		if File.exists?(file)
#			#puts "File exists, checking number of sequences... "
#			case type
#				#when 'gb': n = _check_nseq_gb(file)
#				when 'gb': n = _check_seq_gb(file, nt)
#				when 'size': n = _check_file_size(file)
#			end
#			
#			if type == 'gb'
#				if n.length == 0
#					warn ["[DONE]".green.bold, "Using existing file- skipping"].join(" ")
#				end
#				return n
#			end
#			
#			warn "nseq: " + n.to_s.blue.bold
#			warn "nseq2d: " + nt.to_s.blue.bold
#			if n == -1
#				warn ["[DOWNLOAD]".red.bold, "File was corrupred!- redownloading"].join(" ")
#				return false
#			end
#			if nt == n
#				#puts ">>>> File already downloaded!"
#				warn ["[DONE]".green.bold, "Using existing file- skipping"].join(" ")
#				return false
#			else
#				#puts "File truncated or number of sequences updated! Redownloading..."
#				warn ["[DOWNLOAD]".red.bold, "Existing file truncated or sequence number updated- redownloading"].join(" ")
#				return true
#			end
#		else
#			#puts "File doesn't exists, downloading..."
#			warn ["[DOWNLOAD]".blue.bold, "File does not exist- downloading"].join(" ")
#			return true
#		end
#	end	
end