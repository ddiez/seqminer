require 'Genome'

config = SeqMiner::Config.new
config.basedir = "/Volumes/Biodev/projects/vardb/"
config.debug

gdb = Genome::Set.new("plasmodium.falciparum_3d7", options = {:config => config})
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

#gdb.write_fasta("6frame")
