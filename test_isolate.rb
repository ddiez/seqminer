require 'isolate'

config = SeqMiner::Config.new

ts = Taxon::Set.new
taxon = ts.get_taxon_by_name("borrelia.hermsii")

idb = Isolate::Set.new(taxon)
idb.debug
idb.filter_by_acc(["DQ174321-1", "AF143466-1"])
idb.debug
i = idb.get_seq_by_acc("DQ174321-1")
i.debug