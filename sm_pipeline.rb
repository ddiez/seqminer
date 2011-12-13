#!/usr/bin/env ruby
#
# SeqMiner is a tool for mining sequence information. It aims to
# help detect sequences belonging to specific protein families.
#
# Author::    Diego Diez  (mailto:diego10ruiz@gmail.com)
# Copyright:: Copyright (c) 2010
# License::   Distributes under the same terms as Ruby

require 'seqminer'

# 1.1 create pipelie object.
sm = SeqMiner::Pipeline.new()
#sm = SeqMiner::Pipeline.new("vardb-dr-10", options = {:cleanup_log => true})

# RUN ALL
# run search, get results, write reports, run scan, get results, write reports.
# if it fails you may need to run each step one by one.
#sm.run_all


########################################################################################
# OPTIONAL: filter taxons.
#sm.taxon.filter_by_name("anaplasma.marginale")
#sm.taxon.filter_by_type("spp")
#sm.taxon.filter_by_type("clade")
#sm.taxon.debug

# OPTIONAL: filter families.
#sm.ortholog.filter_by_name("msp2_p44_map1_omp")
#sm.ortholog.debug

## run step by step (instead of run_all above)
# 2.2 optional: search
#sm.build_search
#sm.run_search
#sm.write_nelson
#sm.write_fasta

# 2.3 optional: scan (requires search above)
# run `sh clean_empty_fasta.sh` in vardb-x directory
#sm.build_scan
#sm.run_scan
#sm.get_scan_results
#sm.write_domain