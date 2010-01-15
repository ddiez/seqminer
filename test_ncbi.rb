require 'bio'

Bio::NCBI.default_email = "diez@kuicr.kyoto-u.ac.jp"
ncbi = Bio::NCBI::REST.new

foo_id = ncbi.esearch("anaplasma marginale st_maries", \
	{"db" => "genome", "rettype" => "gb", "retmode" => "txt"})



puts foo_id
foo = ncbi.efetch(foo_id, \
	{"db" => "genome", "rettype" => "gb", "retmode" => "txt"})
puts foo
