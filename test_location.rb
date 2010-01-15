require 'bio'

loc1 = Bio::Location.new('500..510')
puts loc1.from

loc2 = Bio::Location.new('606..610')
puts loc2.from


locs = Bio::Locations.new('complement(join(500..510,601..650))')
puts locs.sequence
#locs.each do |loc|
	#puts loc.from
#end
