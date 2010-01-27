require 'parser'

p = Parser::Refseq.new("foo.gb", "foo")
g = p.parse
g.debug

s = g.get_gene_by_acc("AM010")
s.debug

s = g.get_gene_by_acc("AM033")
s.debug

g.each_value do |gene|
	puts gene.id if gene.length == 0
end

#g.write_fasta("gene", "foo.txt")
#g.write_fasta("cds", "foo2.txt")
#g.write_fasta("protein", "foo3.txt")
g.write_fasta("genome", "genome2.txt")
