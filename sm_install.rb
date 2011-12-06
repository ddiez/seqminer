#!/usr/bin/env ruby
#
# SeqMiner is a tool for mining sequence information. It aims to
# help detect sequences belonging to specific protein families.
#
# Author::    Diego Diez  (mailto:diego10ruiz@gmail.com)
# Copyright:: Copyright (c) 2010
# License::   Distributes under the same terms as Ruby

require 'seqminer'

# 1. Install/Load project.
#sm = SeqMiner::Install.new(nil)
# RUN:
sm = SeqMiner::Install.new("vardb-dr-10", options = {:import => "vardb-dr-9" })
sm.config.debug

# 2. update Pfam (NOT NEEDED IF NOT UPDATED!)
# RUN:
#sm.update_pfam
#sm.process_pfam

#sm.ortholog.debug

# 3. update source sequences.
# EXAMPLES: filtering to focus on some species/clade.
#sm.taxon.filter_by_name("anaplasma.marginale")
#sm.taxon.filter_by_name("borrelia.burgdorferi")
sm.taxon.filter_by_name("babesia.bovis")
#sm.taxon.filter_by_name("plasmodium.falciparum")
#sm.taxon.filter_by_name("plasmodium.yoelii")
#sm.taxon.filter_by_name("plasmodium.vivax")
#sm.taxon.filter_by_name("trypanosoma.brucei")
#sm.taxon.filter_by_name("mycobacterium.tuberculosis_F11")
#sm.taxon.filter_by_source("ncbi")
#sm.taxon.filter_by_type("spp")
#sm.taxon.filter_by_type("clade")
#sm.taxon.debug

# EXAMPLES: filtering to focus on type of sequences.
sm.taxon.filter_by_type("spp")
#sm.taxon.filter_by_type("clade")
sm.taxon.debug

# 3.1 download.
# RUN:
sm.update_sequences
# 3.2 process sequences.
# RUN:
#sm.process_sequences
# 3.3 process directories.
# RUN:
#sm.process_directories

# 4. update HMM models (ONLY NEEDED IF NEW SPECIES/FAMILIES/PFAM !)
#sm.update_hmm

# 4. update PSSM models (ONLY NEEDED IF NEW SPECIES/FAMILIES/PFAM !).
# this has a limitation. it requires first to run an hmmer search to select the best seed.
# alternatives?
# a) specify a suitable seed.
# b) others...?
# 4.1 get seq
# RUN:
#sm2 = SeqMiner::Pipeline.new
#sm2.dir_initialize
#sm2.taxon.filter_by_type("spp")
#sm2.build_search
#sm2.search.search
# RUN:
#sm.update_pssm
