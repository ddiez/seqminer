#!/usr/bin/env ruby
#
# SeqMiner is a tool for mining sequence information. It aims to
# help detect sequences belonging to specific protein families.
#
# Author::    Diego Diez  (mailto:diez@kuicr.kyoto-u.ac.jp)
# Copyright:: Copyright (c) 2010
# License::   Distributes under the same terms as Ruby

require 'seqminer'

sm = SeqMiner::Pipeline.new
sm.config.dir_result = "vardb-3"
sm.taxon.filter_by_type("spp")
sm.build_search
sm.run_all
