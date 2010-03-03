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

i = is.get_item_by_id(2)
puts
i.debug

is.delete(i)
is.debug
is.each_value do |i|
	i.debug
end
