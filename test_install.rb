require 'SeqMiner'

sm = SeqMiner::Install.new
#sm.install

#sm.taxon.filter_by_name("anaplasma.marginale")
#sm.taxon.filter_by_name("babesia.bovis")
#sm.taxon.filter_by_name("plasmodium.falciparum")
#sm.taxon.filter_by_name("plasmodium.yoelii")
#sm.taxon.filter_by_name("anaplasma.phagocytophilum")
#sm.taxon.filter_by_source("ncbi")
#sm.taxon.filter_by_type("spp")
#sm.taxon.filter_by_type("clade")
#sm.taxon.debug

#sm.update_pfam
#sm.process_pfam
#sm.update_sequences
sm.process_sequences
#sm.process_directories
