require 'Taxon'

#ts = Taxon::Set.new(options = {:update_ncbi_info => true})
ts = Taxon::Set.new
ts.debug

#t = ts.get_taxon_by_name("plasmodium.falciparum")
#t.debug
#
#t = ts.get_item_by_id("184922")
#t.debug
#
#ts.filter_by_name("plasmodium")
#ts.debug
#t = ts.get_item_by_id("184922")
#t.debug if ! t.nil?
#
#ts.filter_by_type("spp")
#ts.debug
#
#ts.filter_by_source("plasmodb")
#ts.debug
