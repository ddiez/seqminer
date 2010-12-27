#!/usr/bin/env ruby

require 'seqminer'

sm = SeqMiner::Pipeline.new("vardb-dr-6")
#sm.taxon.filter_by_name("anaplasma.marginale")
#sm.taxon.filter_by_type("spp")
#sm.taxon.debug

#sm.ortholog.filter_by_name("msp2_p44_map1_omp")
#sm.ortholog.debug

# run search, get results, write reports.
# run scan, get results, write reports.
#sm.run_all

# step by step (instead of run_all above)
# search
#sm.build_search
#sm.run_search
#sm.get_search_results
#sm.write_nelson
#sm.write_fasta

# scan
#sm.build_scan
#sm.run_scan
#sm.get_scan_results
#sm.write_domain


# TODO: check all the reports.
# TODO: report to vardb dir.
# report
sm.build_search
sm.get_search_results(eval = 0.01)
#sm.report
#sm.report(0.8)
sm.report_summary
