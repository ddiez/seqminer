require 'progressbar'

file = ARGV[0]
total = system "grep \">\" " + file + " | wc -l"
puts total
