require 'Search'

t1 = Search::Type.new(0, "nucleotide")
t1.debug
ts = Search::TypeSet.new(options = {:empty => true})
ts.debug
ts2 = Search::TypeSet.new
ts2.debug
