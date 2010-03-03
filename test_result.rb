require 'result'

#p = Result::HmmerParser.new("test_result.txt", "test", "protein")
#p = Result::HmmerParser.new("test_result2.txt", "test", "nucleotide")
p = Result::HmmerParser.new("test_result3.txt", "test", "nucleotide")

r = p.parse
r.debug

r.filter_by_eval(0.001)
r.debug
r.each_sequence do |hit|
	hit.debug
end

rs = Result::Set.new
rs << r

r.each_sequence do |hit|
	warn "+ HIT +"
	warn "* hit id: " + hit.id
	warn hit.best_subhit.debug
	warn "--------------------"
end
