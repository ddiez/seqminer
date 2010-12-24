#!/usr/bin/env ruby

require 'seqminer'

sm = SeqMiner::Pipeline.new
#sm.taxon.filter_by_name("anaplasma.marginale")
#sm.taxon.filter_by_type("spp")
#sm.taxon.debug

#sm.ortholog.filter_by_name("msp2_p44_map1_omp")
#sm.ortholog.debug

sm.build_search

# run search, get results, write reports.
# run scan, get results, write reports.
sm.run_all


#sm.get_results(eval = 0.01)
# TODO:
#sm.report
#sm.report(0.8)
#sm.report_summary
