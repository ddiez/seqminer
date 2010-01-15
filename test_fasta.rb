require 'bio'
file = Bio::FastaFormat.open("seq_nuc.fa")
file.each do |entry|
	seq = entry.to_biosequence
	puts seq.to_fasta(seq.definition, 10)
	break
end
