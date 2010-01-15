require 'Config'

class A
	include Config

	def initialize
		super
	end
end

a = A.new
puts a.dir_result
