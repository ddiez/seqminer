require 'SeqMiner'

sm = SeqMiner::Config.new
puts sm.file_taxon
sm.basedir = "./"
puts sm.basedir
puts sm.file_taxon
