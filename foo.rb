a = ["a", "e", "c"]

b = a.sort do |x,y|
	y <=> x
end
puts b
