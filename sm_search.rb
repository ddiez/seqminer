#!/usr/bin/env ruby

require 'SeqMiner'

sm = SeqMiner::Pipeline.new
sm.taxon.filter_by_name("plasmodium.falciparum_3d7")
sm.taxon.filter_by_type("spp")
#sm.taxon.debug

sm.ortholog.filter_by_name("rifin_stevor")
#sm.ortholog.debug

sm.build_search

sm.dir_result = "vardb-3"
puts "* " + sm.dir_result

#sm.search.debug
sm.run
#sm.get_results(eval = 0.01)
# TODO:
#sm.report
#sm.report(0.8)
sm.report_summary
