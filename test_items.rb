require 'item'

is = Item::Set.new
(0..9).each do |idx|
	i = Item::Item.new(idx)
	is << i
end
is.debug
is.each_value do |i|
	i.debug
end
