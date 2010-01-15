require 'SeqMiner'
require 'Item'
require 'bio'

module Sequence
	include Item

	class Set < Set
		attr_accessor :dir, :file, :type
		attr_reader :config

		def initialize(name, type, options = {:config => nil})
			super()

			if ! options[:config]
				@config = SeqMiner::Config.new
			else
				@config = options[:config]
			end
			@dir = config.dir_sequence + name
			@type = type
			@file = @dir + (type + ".fa")
			fi = Bio::FastaFormat.open(@file)
			fi.each do |entry|
				seq = entry.to_biosequence
				case type
				when "gene"
					seq.na
				when "protein"
					seq.aa
				end
				add(seq, seq.accessions[0])
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
