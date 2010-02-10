require 'family'

fs = Family::Set.new
fs.debug

f = fs.get_item_by_id("plasmodium.vivax-vir_kir")
f.debug


f = fs.get_item_by_id("anaplasma.marginale-msp2_p44_map1_omp")
f.debug
