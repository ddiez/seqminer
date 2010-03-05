require 'seqminer'

sm = SeqMiner::Pipeline.new
#sm.dir_initialize
#sm.taxon.filter_by_name(["anaplasma.marginale", "plasmodium.falciparum"])
#sm.taxon.filter_by_type("spp")
#sm.taxon.filter_by_type("clade")
#sm.ortholog.filter_by_name("msp2")
#sm.build_search
#sm.search.search

#sm.run_all

#sm.get_search_results
#sm.write_fasta

#rs = sm.result
#rs.debug
#r = rs.get_item_by_id("anaplasma.marginale_st_maries-msp2_p44_map1_omp")
#r.debug
#hit = r.get_item_by_id("AM1144")
#hit.debug
#sh = hit.get_item_by_id("AM1144")
#sh.debug
#sh.each_domain do |domain|
#	domain.debug
#end
#dom = sh.get_item_by_id("Surface_Ag_2")
#dom.each_domainhit do |dh|
#	dh.debug
#end

sm.build_scan
#sm.run_scan


#sm.get_scan_results
sm.taxon.debug
sm.write_domain
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