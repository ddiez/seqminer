#!/usr/bin/env ruby
#
# SeqMiner is a tool for mining sequence information. It aims to
# help detect sequences belonging to specific protein families.
#
# Author::    Diego Diez  (mailto:diez@kuicr.kyoto-u.ac.jp)
# Copyright:: Copyright (c) 2010
# License::   Distributes under the same terms as Ruby

require 'seqminer'
# 1. create object.
#c = SeqMiner::Commit.new()
c = SeqMiner::Commit.new("vardb-dr-9")
c.debug

# filter by several family parameters.
#c.family.debug
#c.family.filter_by_taxon("plasmodium.falciparum")
#c.family.filter_by_ortholog("var")
#c.family.filter_by_name("var")

# more fine tunning: run only on the clades.
# NOT YET!
#c.taxon.filter_by_type("clade")

# 2. commit files to directory
#c.commit
# 3. get stats.
#c.stat_sequences
# 4. obtain alignments.
#    NOTE: 'align' uses module queue.rb to send multiple alignment jobs in multicore
#    or multiple cpu machines. the default is ncpu = 1. queue.rb does not take into
#    account other users or processes that may be running so choose a sensible
#    paramenter for your system! 
c.align(what = "protein", ncpu = 16)
#c.align(what = "cds", ncpu = 16)
# alternatively do it all at once.
#c.align(ncpu = 16)
