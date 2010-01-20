require 'SeqMiner'
require 'Item'
require 'Sequence'

module Isolate
	include Item

	class Set < Set
		attr_reader :config, :name, :file
		
		def initialize(name, options = {:empty => false, :config => nil})
			super()
			
			if options[:config]
				@config = options[:config]
			else
				@config = SeqMiner::Config.new
			end
			
			if options[:empty]
				@file = "_undef_"
			else
			end
		end
		
		# returns a gene item based on the accession value.
		def get_seq_by_acc(acc)
			get_item_by_id(acc)
		end
		
		def get_seq_by_subid(subid)
			each_value do |seq|
				return seq if seq.subid == subid
			end
			return nil
		end
	end
	
	class Seq < Item
		attr_accessor :isolate, :strain, :clone, :country, :subid, :accession
		attr_accessor :source, :locus, :strand, :from, :to, :description, :pseudogene, :sequence, :trans_table, :type

		def initialize(id)
			super
			
			@pseudogene = 0
			@trans_table = 1 # assume the default and pray we can get the information somewhere.
		end

		def debug
			warn "+ Sequence +"
			warn "* id: " + id
			warn "* subid: " + subid
			warn "* locus: " + locus
			warn "* accession: " + accession
			warn "* description: " + description
			warn "* source: " + source
			warn "* strand: " + strand.to_s
			warn "* location: [" + from.to_s + " - " + to.to_s + "]"
			#warn "* exons: " + length.to_s
			#warn "* splicing: " + splicing
			#warn "* size: " + size.to_s
			#warn "* splicing_ori: " + splicing_original
			warn "* pseudogene: " + pseudogene.to_s
			warn "* type: " + type
			warn "* trans_table: " + trans_table.to_s
			warn ""
		end
	end
end