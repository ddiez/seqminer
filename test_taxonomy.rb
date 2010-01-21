require 'bio'
require 'rexml/document'


Bio::NCBI.default_email = "diez@kuicr.kyoto-u.ac.jp"
ncbi = Bio::NCBI::REST::EFetch.new
tax = ncbi.taxonomy("770", "xml")

doc = REXML::Document.new(tax)
#puts doc.doctype
#puts doc.root
doc.elements.each('TaxaSet/Taxon/GeneticCode/GCId') do |item|
	puts item.text
end