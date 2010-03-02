require 'genome'
require 'taxon'

config = Config::General.new
#config.basedir = "/Volumes/Biodev/projects/vardb/"
#config.debug

ts = Taxon::Set.new
taxon = ts.get_taxon_by_name("plasmodium.knowlesi_h")

gdb = Genome::Set.new(taxon)
gdb.debug
gdb.auto_clean
gdb.debug
gdb.filter_by_acc(["PKH_141170", "PKH_126770"])
gdb.debug
g = gdb.get_gene_by_acc("PKH_126770")
g.debug
g.gene
#
#
#
#puts g.sequence.to_fasta("gene", 200)
#puts
#puts g.cds.to_fasta("cds", 200)
#puts
#puts g.translation(1).to_fasta("protein", 200)
#
#puts g.translation(1, 11).to_fasta("protein", 200)
#
#puts g.translation(1, 1).to_fasta("protein", 200)

#puts g.translation(2).to_fasta("protein", 300)
#puts
#puts g.translation(3).to_fasta("protein", 300)
#puts
#puts g.translation(4).to_fasta("protein", 300)
#puts
#puts g.translation(5).to_fasta("protein", 300)
#puts
#puts g.translation(6).to_fasta("protein", 300)
#puts

#gdb.write_fasta("6frame")
