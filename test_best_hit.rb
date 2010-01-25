require 'Result'

rs = Result::Set.new

['test_result1.txt', 'test_result2.txt', 'test_result3.txt'].each do |file|
	p = Result::HmmerParser.new
	p.file = file
	p.result_id = "test" + "." + file
	p.type = "nucleotide"
	r = p.parse
	rs << r
end


rs.debug
bh = rs.best_hit
bh.debug
