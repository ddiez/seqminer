# SeqMiner is a tool for mining sequence information. It aims to
# help detect sequences belonging to specific protein families.
#
# Author::    Diego Diez  (mailto:diego10ruiz@gmail.com)
# Copyright:: Copyright (c) 2010
# License::   Distributes under the same terms as Ruby

require 'term/ansicolor'

# This module contains methods common to all other modules. Should be potentially included in all other definitions.

class String
	include Term::ANSIColor
end

module Common
	private
	
	def error msg = ""
		_error msg, file_log
	end
	
	def warn msg = ""
		_warn msg, file_log
	end
	
	def info msg = ""
		_info msg, file_log
	end
	
	def _print msg = "", file = nil
		if file
			$stderr = File.new(file, "a")
			$stderr.puts msg
			$stderr.close
		else
			$stderr.puts msg
		end
	ensure
		$stderr = STDERR
	end
	
	def _warn msg, file = nil
		_print "[WARNING] ".red + msg
		_print "[WARNING] " + msg, file if file
	end
	
	def _error msg, file = nil
		_print "[ERROR] ".red + msg
		_print "[ERROR] " + msg, file if file
	end
	
	def _info msg = nil, file = nil
		_print msg
		_print msg, file if file
	end	
	# Checks the result of a tool and exits if it fails and the argument exitonfail is true (default).
	# It uses term/ansicolor for fancy terminal coloring.
	# === Arguments:
	# res:: result from an execute method
	# exitonfail:: [true, false] controls wheter the funcion should terminate the running process on fail.
	# msg:: Error message to append to error report.
	def _check_result(res, exitonfail = true, msg = "an error has occurred")
		if res
			info "[DONE]".green.bold
		else
			info ["[FAIL]", msg].join(" ").blink.red.bold
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
			info "* downloaded: " + gid.length.to_s.blue
			rid = rid - gid
			info "* remaining: " + rid.length.to_s.red
			
			if rid.length == 0
				info "* " + "[DONE]".green.bold + " using existing file- skipping"
			else
				info "* " + "[DOWNLOAD]".red.bold + " existing file truncated but seems OK- downloading rest of sequences"
			end
		else
			info "* " + "[DOWNLOAD]".blue.bold + " file does not exist- downloading"
		end
		return rid
	end
	
	def _check_download_size(file, fsize)
		if File.exists?(file)
			s = _check_file_size(file)
			info "* downloaded: " + s.to_s.blue
			if s != fsize
				info "* " + "[DOWNLOAD]".red.bold + " file was corrupred!- redownloading"
				File.unlink file
				return true
			else
				info "* " + "[DONE]".green.bold + " using existing file- skipping"
				return false
			end
		else
			info "* " + "[DOWNLOAD]".blue.bold + " file does not exist- downloading"
			return true
		end
	end
	
	# this function check for duplicated entries in GenBank files (same LOCUS, different version and GI)
	# and writes a new file that only uses the latest version of an entry, and writes discarded version
	# into a file.
	def _check_duplicates_gb(file)
		info "* check duplicates: " + file
		system "./check_duplicates_gb.pl " + file
	end
	
#	def _check_download(file, nt, type)
#		#warn "number of sequences to download: " + nt.to_s
#		# check if file exists.
#		if File.exists?(file)
#			#warn "File exists, checking number of sequences... "
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
#				#warn ">>>> File already downloaded!"
#				warn ["[DONE]".green.bold, "Using existing file- skipping"].join(" ")
#				return false
#			else
#				#warn "File truncated or number of sequences updated! Redownloading..."
#				warn ["[DOWNLOAD]".red.bold, "Existing file truncated or sequence number updated- redownloading"].join(" ")
#				return true
#			end
#		else
#			#warn "File doesn't exists, downloading..."
#			warn ["[DOWNLOAD]".blue.bold, "File does not exist- downloading"].join(" ")
#			return true
#		end
#	end	
end
