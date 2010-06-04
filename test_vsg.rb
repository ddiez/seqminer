require 'genome'
require 'taxon'

ts = Taxon::Set.new
t = ts.get_taxon_by_name("trypanosoma.brucei_TREU927")
t.debug
g = Genome::Set.new(t)
g.debug
ids = []
#File.open("vsg_list.txt").each do |line|
File.open(ARGV[0]).each do |line|
	line.chomp!
	ids << line
end
g.filter_by_acc(ids)
g.debug
g.write_nelson("vsg", "trypanosoma.brucei_TREU927-vsgdb.txt")
