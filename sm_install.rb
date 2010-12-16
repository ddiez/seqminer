require 'seqminer'

sm = SeqMiner::Install.new

#sm.config.debug
#sm.install

# 2. update Pfam.
#sm.update_pfam
#sm.process_pfam

#sm.taxon.filter_by_name("anaplasma.marginale")
#sm.taxon.filter_by_name("babesia.bovis")
#sm.taxon.filter_by_name("plasmodium.falciparum")
#sm.taxon.filter_by_name("plasmodium.yoelii")
#sm.taxon.filter_by_name("trypanosoma.brucei")
#sm.taxon.filter_by_source("ncbi")
#sm.taxon.filter_by_type("spp")
#sm.taxon.filter_by_type("clade")
#sm.taxon.debug

#sm.taxon.filter_by_type("spp")
sm.taxon.filter_by_type("clade")
sm.taxon.debug

# 3. download sequences.
sm.update_sequences

# 4. process sequences.
#sm.process_sequences

#
#sm.process_directories
#sm.update_pssm
