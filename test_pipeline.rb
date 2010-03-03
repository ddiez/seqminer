require 'seqminer'

sm = SeqMiner::Pipeline.new
#sm.dir_initialize
sm.taxon.filter_by_name("anaplasma.marginale")
#sm.taxon.filter_by_type("spp")
#sm.taxon.filter_by_type("clade")
sm.ortholog.filter_by_name("msp2")
sm.build_search
sm.search.debug
sm.search.each_search do |s|
	s.debug
end
#sm.run_all
#sm.run_scan

sm.get_search_results
rs = sm.result
rs.debug
r = rs.get_item_by_id("anaplasma.marginale_st_maries-msp2_p44_map1_omp")
r.debug
hit = r.get_item_by_id("AM1144")
hit.debug
sh = hit.get_item_by_id("AM1144")
sh.debug
sh.each_domain do |domain|
	domain.debug
end
dom = sh.get_item_by_id("Surface_Ag_2")
dom.each_domainhit do |dh|
	dh.debug
end
#sm.get_scan_results
#rs = sm.scan_result
#r = rs.get_item_by_id("plasmodium.falciparum_3d7-var")
#r.debug
#hit = r.get_item_by_id("PFD0615c")
#hit.debug
#sh = hit.get_item_by_id("PFD0615c")
#sh.debug
#sh.each_domain do |domain|
#	domain.debug
#end
#dom = sh.get_item_by_id("PFEMP")
#dom.each_domainhit do |dh|
#	dh.debug
#end