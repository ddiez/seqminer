require 'bio'

seq = Bio::Sequence::NA.new("atgcatgcaaaa")
#seq = Bio::Sequence::NA.new("")
puts seq
puts seq.length
puts seq.translate
puts seq.translate(2)
puts seq.translate(3)

puts seq.complement
puts seq.complement.translate
puts seq.complement.translate(2)
puts seq.complement.translate(3)
