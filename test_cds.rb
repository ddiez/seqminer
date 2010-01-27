require 'taxon'
require 'genome'

genome = Genome::Set.new("plasmodium.yoelii_17xnl", "gene")
#gene = genome.get_item_by_id("PY01186")
gene = genome.get_item_by_id("PY00122")
gene.debug
puts gene.sequence
puts
puts gene.cds
puts
puts gene.translation
puts
