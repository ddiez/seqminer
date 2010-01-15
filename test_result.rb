require 'Result'

#r = Result::HmmerParser.new("test_result.txt", "test", "protein")
#r = Result::HmmerParser.new("test_result2.txt", "test", "nucleotide")
r = Result::HmmerParser.new("test_result3.txt", "test", "nucleotide")

r.result.debug

#r.result.filter_by_eval(0.001)
#r.result.debug
#r.result.items.each_value do |hit|
#	$stderr.puts "* id: " + hit.id
#	$stderr.puts "* has_fragment?: " + hit.has_fragment?.to_s
#	$stderr.puts "* has_complete?: " + hit.has_complete?.to_s
#	$stderr.puts "* coherent?: " + hit.coherent?.to_s
#end

rs = Result::Set.new
rs << r.result

r.result.items.each_value do |hit|
	warn "+ HIT +"
	warn "* hit id: " + hit.id
	warn hit.best_subhit.debug
	warn "--------------------"
end
