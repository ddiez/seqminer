require 'tools'

t = Tools::Hmmer.new("hmmsearch")
#t.tool = "hmmsearch"
t.model = "PFEMP"
t.infile = "test_hmmer.fa"
t.outfile = "test_hmmer.log"
t.debug
#t.execute
