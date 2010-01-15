require 'Search'

p = Search::Parameter.new
p.debug

p.taxon.filter_by_name("plasmodium")
p.ortholog.filter_by_name("var")
p.debug
