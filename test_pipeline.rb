require 'SeqMiner'

sm = SeqMiner::Pipeline.new
#sm.taxon.filter_by_name("anaplasma.marginale")
sm.taxon.filter_by_type("spp")
#sm.ortholog.filter_by_name("msp2")
sm.build_search
sm.search.debug
sm.run_all
