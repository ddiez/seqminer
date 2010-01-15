require 'Genome'

ts = Taxon::Set.new
ts.filter_by_type('spp')
ts.debug

ts.each_value do |taxon|
	genome = Genome::Set.new(taxon)
	genome.each_value do |gene|
		puts gene.cds
	end
end
