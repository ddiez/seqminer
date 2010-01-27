require 'taxon'
require 'genome'

ts = Taxon::Set.new
taxon = ts.get_taxon_by_name("plasmodium.yoelii_17xnl")

genome = Genome::Set.new(taxon, "gene")
#gene = genome.get_item_by_id("PY01186")
gene = genome.get_item_by_id("PY00122")
gene.debug
puts gene.sequence
puts
puts gene.cds
puts
puts gene.translation
puts
