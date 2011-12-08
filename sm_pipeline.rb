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
#sm = SeqMiner::Pipeline.new()
#sm = SeqMiner::Pipeline.new("vardb-dr-9")
sm = SeqMiner::Pipeline.new("vardb-dr-10")

# 1.2 optional: filter taxons.
#sm.taxon.filter_by_name("anaplasma.marginale")
#sm.taxon.filter_by_type("spp")
#sm.taxon.filter_by_type("clade")
sm.taxon.debug

# 1.3 optional: filter families.
#sm.ortholog.filter_by_name("msp2_p44_map1_omp")
sm.ortholog.debug

## run all.
# 2.1 run search, get results, write reports, run scan, get results, write reports.
#sm.run_all

## run step by step (instead of run_all above)
# 2.2 optional: search
#sm.dir_initialize
sm.build_search
sm.search.debug
#sm.run_search
sm.get_search_results
sm.write_nelson
sm.write_fasta

# 2.3 optional: scan (requires search above)
# run `sh clean_empty_fasta.sh` in vardb-x directory
#sm.build_scan
#sm.run_scan
#sm.get_scan_results
#sm.write_domain

# 3.1 report (SKIP THIS PART!!)
# TODO: check WHICH report are needed and fix implementation!
#sm.build_search
#sm.get_search_results(eval = 0.01)
# report NOT working.
#sm.report
#sm.report(0.8)
# summary working- but uselful?
#sm.report_summary
