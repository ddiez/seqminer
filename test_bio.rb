#require 'bio'
require 'bio'
seq = Bio::Sequence::NA.new("atgcatgcaaaa")
puts seq
puts seq.translate
puts seq.translate(2)
puts seq.translate(3)

puts seq.complement
puts seq.complement.translate
puts seq.complement.translate(2)
puts seq.complement.translate(3)
