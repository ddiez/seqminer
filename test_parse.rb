require 'Parser'

p = Parser::Eupathdb.new("foo.gff", "foo")
g = p.parse

ps = 0
g.each_value do |gene|
	ps += 1 if gene.pseudogene == 1
	#gene.debug
end
#puts "======================="
g.debug
warn "* pseudogenes: " + ps.to_s

g.write_fasta("gene")
g.write_fasta("cds")
g.write_fasta("protein")
