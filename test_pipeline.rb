require 'seqminer'

sm = SeqMiner::Pipeline.new
#sm.dir_initialize
#sm.taxon.filter_by_name("anaplasma.marginale")
#sm.taxon.filter_by_type("spp")
#sm.taxon.filter_by_type("clade")
#sm.ortholog.filter_by_name("msp2")
#sm.build_search
#sm.search.debug
#sm.run_all
sm.run_scan
#sm.get_scan_results
