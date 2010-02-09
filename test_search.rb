require 'search'

p = Search::Parameter.new
p.taxon.filter_by_name("anaplasma.marginale")
p.taxon.filter_by_type("spp")
p.ortholog.filter_by_name("msp2")
p.debug

ss = Search::Set.new(p)
ss.debug
#ss.search

rs = ss.parse
rs.debug
#rs.write_fasta
#rs.write_nelson
rsm = rs.auto_merge
rsm.debug
rsm.report
#rsm.report_summary
