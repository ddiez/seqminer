require 'seqminer'

sm = SeqMiner::Install.new("vardb-dr-9")
#sm = SeqMiner::Install.new("rasome-3")

sm.config.debug
#sm.install

# 2. update Pfam.
#sm.update_pfam
#sm.process_pfam

#sm.taxon.filter_by_name("anaplasma.marginale")
#sm.taxon.filter_by_name("borrelia.burgdorferi")
#sm.taxon.filter_by_name("babesia.bovis")
#sm.taxon.filter_by_name("plasmodium.falciparum")
#sm.taxon.filter_by_name("plasmodium.yoelii")
#sm.taxon.filter_by_name("plasmodium.vivax")
#sm.taxon.filter_by_name("trypanosoma.brucei")
#sm.taxon.filter_by_name("mycobacterium.tuberculosis_F11")
#sm.taxon.filter_by_source("ncbi")
#sm.taxon.filter_by_type("spp")
#sm.taxon.filter_by_type("clade")
#sm.taxon.debug

#sm.taxon.filter_by_type("spp")
#sm.taxon.filter_by_type("clade")
#sm.taxon.debug

#sm.ortholog.debug

# 3. download sequences.
#sm.update_sequences

# 4. process sequences.
#sm.process_sequences

# 5. process directories.
#sm.process_directories

# 6. update HMM models.
#sm.update_hmm

# 7. update PSSM models.
# this has a limitation. it requires first to run an hmmer search to select the best seed.
# alternatives?
# 1. specify a suitable seed.
# 2. others...?
# 
#sm2 = SeqMiner::Pipeline.new
#sm2.dir_initialize
#sm2.taxon.filter_by_type("spp")
#sm2.build_search
#sm2.search.search

#sm.update_pssm
