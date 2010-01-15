require 'Taxon'
require 'Genome'

ts = Taxon::Set.new
t = ts.get_taxon_by_name("plasmodium.falciparum_3d7")
t.debug

gdb = Genome::Set.new(t)
gdb.debug
#g = gdb.get_gene_by_acc("PFD1155w")
g = gdb.get_gene_by_acc("MAL13P1.105")
g.debug
puts g.sequence.to_fasta("gene", 300)
puts
puts g.cds.to_fasta("cds", 300)
puts
puts g.translation(1).to_fasta("protein", 300)
puts
puts g.translation(2).to_fasta("protein", 300)
puts
puts g.translation(3).to_fasta("protein", 300)
puts
puts g.translation(4).to_fasta("protein", 300)
puts
puts g.translation(5).to_fasta("protein", 300)
puts
puts g.translation(6).to_fasta("protein", 300)
puts
