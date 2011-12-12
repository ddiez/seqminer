require 'taxon'

#ts = Taxon::Set.new(options = {:update_ncbi_info => true})
ts = Taxon::Set.new(options = {:project => "vardb-dr-10"})
ts.debug

#t = ts.get_taxon_by_name("plasmodium.falciparum_3d7")
#t.debug
#puts t.binomial
#
#t = ts.get_item_by_id("184922")
#t.debug
#
#ts.filter_by_name(["plasmodium", "anaplasma"])
#ts.filter_by_name("plasmodium")
#ts.filter_by_type("spp")
#ts.debug
#t = ts.get_item_by_id("184922")
#t.debug if ! t.nil?
#
#ts.filter_by_type("spp")
#ts.debug
#
#ts.filter_by_source("plasmodb")
#ts.debug
