#!/usr/bin/env ruby
#
require 'SeqMiner'

sm = SeqMiner::Pipeline.new
sm.config.dir_result = "vardb-3"
sm.taxon.filter_by_type("spp")
sm.build_search
sm.run_all
