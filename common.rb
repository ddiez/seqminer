# SeqMiner is a tool for mining sequence information. It aims to
# help detect sequences belonging to specific protein families.
#
# Author::    Diego Diez  (mailto:diez@kuicr.kyoto-u.ac.jp)
# Copyright:: Copyright (c) 2010
# License::   Distributes under the same terms as Ruby

require 'term/ansicolor'

# This module contains methods common to all other modules. Should be potentially included in all other definitions.

class String
	include Term::ANSIColor
end

module Common
	# Checks the result of a tool and exits if it fails and the argument exitonfail is true (default).
	# It uses term/ansicolor for fancy terminal coloring.
	# === Arguments:
	# res:: result from an execute method
	# exitonfail:: [true, false] controls wheter the funcion should terminate the running process on fail.
	# msg:: Error message to append to error report.
	def _check_result(res, exitonfail = true, msg = "an error has occurred")
		if res
			warn "[DONE]".green.bold
		else
			warn ["[FAIL]", msg].join(" ").blink.red.bold
			exit if exitonfail
		end
	end
end