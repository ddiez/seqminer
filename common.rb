require 'term/ansicolor'

module Common
	def _check_result(res)
		if res
			$stderr.puts green, bold, "[DONE]", reset
		else
			$stderr.puts red, bold, "[FAIL]", reset
			exit
		end
	end
end