# SeqMiner is a tool for mining sequence information. It aims to
# help detect sequences belonging to specific protein families.
#
# Author::    Diego Diez  (mailto:diez@kuicr.kyoto-u.ac.jp)
# Copyright:: Copyright (c) 2010
# License::   Distributes under the same terms as Ruby

require 'config'
require 'item'
require 'bio'
require 'progressbar'

module Sequence
	include Item

	class Set < Set
		attr_accessor :dir, :file, :type
		attr_reader :config

		def initialize(name, type, options = {:config => nil})
			super()

			if options[:config]
				@config = options[:config]
			else
				@config = Config::General.new
			end
			@dir = config.dir_sequence + name
			@type = type
			@file = @dir + (type + ".fa")
			
#			warn "* file: " + file
#			total = `grep ">" #{file} | wc -l`
#			total.strip!
#			puts "* number sequences: " + total
#			number_read = 0
#			pb = ProgressBar.new(file.to_s, 100)
			fi = Bio::FastaFormat.open(file)
			fi.each do |entry|
				seq = entry.to_biosequence
				case type
				when "gene"
					seq.na
				when "protein"
					seq.aa
				end
				add(seq, seq.accessions[0])
#				number_read += 1
#				percent_finished = 100 * (number_read.to_f / total.to_f)
#				pb.set(percent_finished)
			end
#			pb.finish
		end
		
		def each_sequence
			each_value do |value|
				yield value
			end
		end

		def get_seq_by_acc(acc)
			get_item_by_id(acc)
		end

		def debug
			warn "+ Sequence +"
			warn "* dir: " + dir
			warn "* type: " + type
			warn "* file: " + file
			warn "* sequences: " + length.to_s
		end
	end
end
