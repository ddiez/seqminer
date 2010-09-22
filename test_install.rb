require 'seqminer'

sm = SeqMiner::Install.new
#sm.install


#sm.update_pfam
#sm.process_pfam

#sm.taxon.load_ncbi_info(update = true)

#sm.taxon.filter_by_name("anaplasma.marginale")
#sm.taxon.filter_by_name("babesia.bovis")
#sm.taxon.filter_by_name("plasmodium.falciparum")
#sm.taxon.filter_by_name("plasmodium.yoelii")
#sm.taxon.filter_by_name("plasmodium.vivax")
#sm.taxon.filter_by_name("trypanosoma.brucei")
#sm.taxon.filter_by_name("trypanosoma.cruzi")
#sm.taxon.filter_by_source("plasmodb")

#sm.taxon.filter_by_type("spp")
#sm.taxon.filter_by_type("clade")
#sm.taxon.debug


#sm.update_sequences
#sm.process_sequences
#sm.process_directories

#sm.update_hmm
# need to run hmm search first for this:
sm.update_pssm
