#!/usr/bin/env ruby
#
require 'bio'
require 'SeqMiner'
require 'Taxon'

sm = SeqMiner::Config.new

ts = Taxon::Set.new
ts.filter_by_type('spp')
ts.debug

ts.items.each do |taxon|
	taxon.debug
	outfile = sm.dir_genome + taxon.name + "/nucleotide.fa"
	fo = File.new(outfile, "w")
	infile = sm.dir_genome + taxon.name + "/gene.fa"
	fi = Bio::FastaFormat.open(infile)
	fi.each do |entry|
		s = entry.to_biosequence
		s.na
		if s.length >= 3
			fo.puts s.translate(1).to_fasta(s.definition + " [strand=1;phase=1]", 60)
			fo.puts s.translate(2).to_fasta(s.definition + " [strand=1;phase=2]", 60)
			fo.puts s.translate(3).to_fasta(s.definition + " [strand=1;phase=3]", 60)
			fo.puts s.complement.translate(1).to_fasta(s.definition + " [strand=-1;phase=1]", 60)
			fo.puts s.complement.translate(2).to_fasta(s.definition + " [strand=-1;phase=2]", 60)
			fo.puts s.complement.translate(3).to_fasta(s.definition + " [strand=-1;phase=3]", 60)
		end
	end
	fi.close
	fo.close
end
