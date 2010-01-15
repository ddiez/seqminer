require 'Sequence'

sdb = Sequence::Set.new("anaplasma.marginale_st_maries", "protein")
sdb.debug
s = sdb.get_seq_by_acc("AM1359")
puts s.to_fasta(s.definition)
