require 'bio'

seq = 'gattaca'
scheme = Bio::ColorScheme::Zappo
postfix = '</span>'
html = ''
seq.each_byte do |c|
color = scheme[c.chr]
prefix = %Q(<span style="background:\##{color};">)
html += prefix + c.chr + postfix
end

puts html
