module Item

	class Set
		attr_reader :items

		def initialize
			@items = {}
		end
		
		def << (*args)
			add(*args)
		end
		
		def add(*args)
			case args.length
			when 1
				item = args[0]
				id = item.id
			when 2
				item = args[0]
				id = args[1]
			end
			
			if items.has_key?(id)
				raise "Item with id #{id} already exists, use replace instead!"
			else	
				items[id] = item
			end
		end

		def replace(item)
			if items.has_key?(item.id)
				items[item.id] = item
			else
				warn "WARNING: replace item (#{item.id}) not found! Replace aborted"
			end
		end
		
		def length
			items.length
		end
		
		def get_item_by_id(id)
			if items.has_key?(id)
				return items[id]
			else
				return nil
			end
		end
		
		def each_value
			items.each_value do |value|
				yield value
			end
		end

		def debug
			warn "* length: " + self.length.to_s
			each_value do |item|
				item.debug
			end
			warn ""
		end
	end

	class Item < Set
		attr_accessor :id

		def initialize (id)
			super()
			@id = id
		end

		def debug
			warn "id: #{@id} => #{self}"
		end
	end
end
