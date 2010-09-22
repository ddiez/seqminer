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

# filter taxons.
sm.taxon.filter_by_name("plasmodium.falciparum")
#sm.taxon.filter_by_type("spp")
sm.taxon.filter_by_type("clade")

# If first time and not run_all()...
#sm.dir_initialize

# filter orthologs.
sm.ortholog.filter_by_name("var")

# search.
#sm.build_search
#sm.search.debug
#sm.run_all
#sm.run_search
#sm.write_fasta
#sm.write_nelson

# scan.
sm.build_scan
sm.scan.debug
sm.run_scan
sm.write_domain
