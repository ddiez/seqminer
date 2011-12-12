require 'ortholog'

os = Ortholog::Set.new(options = {:project => "vardb-dr-10"})
#o = Ortholog::Ortholog.new("var", "PFEMP")
#o.debug
#os.add(o)
#o = Ortholog::Ortholog.new("vir_kir", "Plasmodium_vir")
#o.debug
#os.add(o)
os.debug

#os.filter_by_name(["var", "vir"])
#os.filter_by_name("var")
#os.debug
