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
sm = SeqMiner::Install.new()
# RUN:
# :import => specify a project to import data from; usually the previous release
# :import_source => specify if the source directory is also imported; usually true
# :cleanup_log => specify if the log file (log_install.txt) should be created new; usually true
#sm = SeqMiner::Install.new("vardb-dr-10", options = {:import => "vardb-dr-9", :import_source => true, :cleanup_log => true})
#sm = SeqMiner::Install.new("vardb-dr-11", options = {:import => "vardb-dr-10", :import_source => true, :cleanup_log => true})
#sm.debug

# INSTALL BASIC
# this install option will run all steps in 3, and assumes steps 2 and 4 are not needed.
# this is true when no new families or species are added compared to the imported project.
#sm.install_basic

# INSTALL ALL
# this runs all the steps below.
# it may break, in which case it is better to run them one by one
#sm.install_all

# 2. update Pfam (NOT NEEDED IF NOT UPDATED!)
# RUN:
#sm.update_pfam
#sm.process_pfam

# 3. update source sequences.
# this step will:
# - download sequences from sources (plasmodb, ncbi).
# - process source data into common format.
# - create blast databases from FASTA files.

# OPTIONAL: filtering to focus on some species/clade.
# This is useful to debug or install a single species
#sm.taxon.filter_by_name("anaplasma.marginale")
#sm.taxon.filter_by_name("borrelia.burgdorferi")
#sm.taxon.filter_by_name("babesia.bovis")
#sm.taxon.filter_by_name("plasmodium.falciparum")
#sm.taxon.filter_by_name("plasmodium.yoelii")
#sm.taxon.filter_by_name("plasmodium.berghei_anka")
#sm.taxon.filter_by_name("plasmodium.vivax")
#sm.taxon.filter_by_name("trypanosoma.brucei")
#sm.taxon.filter_by_name("mycobacterium.tuberculosis_F11")

# OPTIONAL: filtering to focus on type of sequences.
# This is useful to debug. In general it is a good idea to run each step for 'spp' and 'clade'
# separately since they use different framework and so the source of problems use to be diff-
# erent. This way you can isolate better potential problems.
#sm.taxon.filter_by_type("spp")
#sm.taxon.filter_by_type("clade")

# to check taxons included after filtering:
#sm.taxon.debug

# RUN:
# 3.1 download source sequences.
#sm.update_sequences
# 3.2 process sequences into common format.
#sm.process_sequences
# 3.3 create blast databases.
#sm.process_directories

# OPTIONAL:
# 4. update models for searches (ONLY NEEDED IF NEW SPECIES/FAMILIES/PFAM !) 
# 4.1 update HMM models.
#sm.update_hmm
# 4.2 update PSSM models.
# this has a limitation. it requires first to run an hmmer search to select the best seed.
# - get HMM sequences:
#sm2 = SeqMiner::Pipeline.new
#sm2.dir_initialize
#sm2.taxon.filter_by_type("spp")
#sm2.build_search
#sm2.search.search
# - update models.
#sm.update_pssm
