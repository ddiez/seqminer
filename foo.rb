module A
	class B
		attr_reader :a
		def initialize
			@a = 10
		end
	end
end

a = A::B.new
puts a.a
