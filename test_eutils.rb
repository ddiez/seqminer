require 'bio'


Bio::NCBI.default_email = "diez@kuicr.kyoto-u.ac.jp"
ncbi = Bio::NCBI::REST.new
puts ncbi.einfo

