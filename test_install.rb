require 'SeqMiner'

sm = SeqMiner::Install.new
#sm.install

#sm.taxon.filter_by_name("babesia.bovis_T2Bo")
#sm.taxon.filter_by_source("ncbi")
sm.taxon.filter_by_type("spp")
#sm.taxon.debug

#sm.update_pfam
#sm.process_pfam
#sm.update_sequences
sm.process_sequences
