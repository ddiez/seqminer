require 'result'

rs = Result::Set.new

ts = Taxon::Set.new
taxon = ts.get_taxon_by_name("plasmodium.falciparum_3d7")

os = Ortholog::Set.new
o = os.get_ortholog_by_name("var")

['test_result1.txt', 'test_result2.txt', 'test_result3.txt'].each do |file|
	p = Result::HmmerParser.new(options = {:taxon => taxon, :ortholog => o})
	p.file = file
	p.result_id = "test" + "." + file
	p.type = "nucleotide"
	r = p.parse
	r.taxon = taxon
	r.type = "6frame"
	rs << r
end


rs.debug
bh = rs.best_hit(limit = ["protein", "nucleotide"])
bh.debug
