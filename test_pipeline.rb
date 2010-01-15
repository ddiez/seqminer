require 'SeqMiner'

sm = SeqMiner::Pipeline.new
puts sm.config.basedir
puts sm.config.dir_result
sm.config.dir_result = "foo"
puts sm.config.dir_result
#sm.dir_initialize
sm.taxon.filter_by_name("anaplasma.marginale")
sm.taxon.filter_by_type("spp")
sm.ortholog.filter_by_name("msp2")
sm.build_search
sm.search.debug
sm.run_all
