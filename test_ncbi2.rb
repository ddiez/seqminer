require 'bio'

Bio::NCBI.default_email = "diez@kuicr.kyoto-u.ac.jp"
ncbi = Bio::NCBI::REST.new
		
id = 770
term = "txid"+id+"[Organism:exp]"
puts term
gpid = ncbi.esearch(term, {:db => "nuccore"}, limit = 10)
puts gpid.length

foo = ncbi.efetch(gpid, {:db => "nuccore", :rettype => "gb", :retmode => "txt"})
puts foo
