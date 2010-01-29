require 'tools'

ts = Tools::Blast.new("makeblastdb")
ts.db = "cds"
ts.dbtype = "nucl"
ts.dbtitle = "CDS from my species"
ts.infile = "cds.fa"
ts.debug

ts = Tools::Hmmer.new("hmmsearch")
ts.infile = "foo.fa"
ts.model = "var"
ts.outfile = "foo.log"
ts.debug

ts = Tools::Hmmer.new("hmmpress")
ts.infile = "foo.hmm"
ts.debug
