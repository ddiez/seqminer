require 'isolate'

config = SeqMiner::Config.new

ts = Taxon::Set.new
taxon = ts.get_taxon_by_name("plasmodium.falciparum")

idb = Isolate::Set.new(taxon)
idb.debug
idb.filter_by_acc(["GE641107", "EE575117"])
idb.debug
i = idb.get_seq_by_acc("GE641107")
i.debug
puts i.sequence.to_fasta("sequence", 60)
puts "#" + i.translation + "#"