require 'parser'

config = SeqMiner::Config.new

p = Parser::Eupathdb.new(config.dir_source + "plasmodium.vivax_salvador1" + "plasmodium.vivax_salvador1.gff", "plasmodium.vivax_salvador1", options = {:config => config})
g = p.parse

ps = 0
g.each_value do |gene|
	ps += 1 if gene.pseudogene == 1
	#gene.debug
end
#puts "======================="
g.debug
warn "* pseudogenes: " + ps.to_s

#g.write_fasta("gene", "gene.txt")
#g.write_fasta("cds", "cds.txt")
#g.write_fasta("protein", "protein.txt")
#g.write_fasta("6frame", "6frame.txt")
g.write_fasta("genome", "genome.txt")
#g.write_gff("gff.txt")
