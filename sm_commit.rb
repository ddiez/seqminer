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
c = SeqMiner::Commit.new("vardb-dr-6")
c.debug

# filter by several family parameters.
c.family.filter_by_taxon("plasmodium.falciparum")
c.family.filter_by_ortholog("var")
#c.family.filter_by_name("var")

# more fine tunning: run only on the clades.
c.taxon.filter_by_type("clade")

# 2. commit files to directory
#c.commit
# 3. get stats.
#c.stat_sequences
# 4. obtain alignments.
c.align(what = "cds")