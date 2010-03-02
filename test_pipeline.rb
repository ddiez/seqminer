require 'seqminer'

sm = SeqMiner::Pipeline.new
#sm.dir_initialize
#sm.taxon.filter_by_name("anaplasma.marginale")
#sm.taxon.filter_by_type("spp")
#sm.taxon.filter_by_type("clade")
#sm.ortholog.filter_by_name("msp2")
#sm.build_search
#sm.search.debug
#sm.run_all
sm.run_scan


#sm.get_scan_results
#rs = sm.scan_result
#r = rs.get_item_by_id("plasmodium.falciparum_3d7.var")
#r.debug
#hit = r.get_item_by_id("PFEMP")
#hit.debug
#sh = hit.get_item_by_id("PFEMP")
#sh.debug
#sh.each_domain do |domain|
#	domain.debug
#end