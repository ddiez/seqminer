require 'bio'
require 'rexml/document'


Bio::NCBI.default_email = "diez@kuicr.kyoto-u.ac.jp"
ncbi = Bio::NCBI::REST::EFetch.new
tax = ncbi.taxonomy("770 948 5850", "xml")
doc = REXML::Document.new(tax)
#puts doc.doctype
puts doc.root
id = []
code = []
doc.elements.each('TaxaSet/Taxon/TaxId') do |item|
	id << item.text
end
doc.elements.each('TaxaSet/Taxon/GeneticCode/GCId') do |item|
	code << item.text
end

id.each_index do |index|
	puts id[index] + "\t" + code[index]
end