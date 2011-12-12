require 'download'
require 'taxon'

ts = Taxon::Set.new(options = {:project => 'vardb-dr-10'})
ts.config.debug
#ts.filter_by_name("anaplasma")
#ts.filter_by_name("plasmodium")
#ts.filter_by_name("trypanosoma")
#ts.filter_by_name("anaplasma.")
#ts.filter_by_type("spp")
#ts.debug
#d1 = Download::Set.new(ts, options = {:config => ts.config})
#d1.debug
#d1.download
