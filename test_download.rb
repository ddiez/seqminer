require 'Download'


ts = Taxon::Set.new
#ts.filter_by_name("anaplasma")
#ts.filter_by_name("plasmodium")
#ts.filter_by_name("trypanosoma")
ts.filter_by_name("leishmania")
ts.filter_by_type("spp")
d1 = Download::Set.new(ts)
#d1.debug
d1.download
