require 'bio'

Bio::NCBI.default_email = "vardb@kuicr.kyoto-u.ac.jp"
ncbi = Bio::NCBI::REST.new
#puts ncbi.einfo

id = "txid234826"+" AND RefSeq Genome[Project Data Type]"
db = "bioproject"
#id = "txid234826[orgn]+AND+RefSeq+Genome[Project Data Type]"
#id = "txid234826[orgn]+RefSeq+Genome"
#id = "txidi498736[orgn]+RefSeq+Genome"
res = ncbi.esearch(id, {"db" => db, "retmode" => "xml"})
puts "* BioProject:"
puts res

#res = ncbi.esearch(res[0]+"[BioProject]", {"db" => "nuccore"})
resf = []
res.each do |r|
	resf = resf + ncbi.esearch(r+"[BioProject]", {"db" => "nuccore"})
end
puts "* nuccore:"
puts resf

res = ncbi.efetch(resf, {"db" => "nuccore", "rettype" => "gb" })
puts res

#id = "NC_004842.2"
#res = ncbi.efetch(id, {"db" => "nucleotide", "rettype" => "gb"})
