require 'tools'

ts = Tools::BlastPlus.new("makeblastdb")
ts.db = "cds"
ts.dbtype = "nucl"
ts.dbtitle = "CDS from my species"
ts.infile = "cds.fa"
ts.debug


ts = Tools::Blast.new("formatdb")
ts.db = "cds"
ts.dbtype = "F"
ts.dbtitle = "CDS from my species"
ts.infile = "cds.fa"
ts.debug


ts = Tools::Hmmer.new("hmmsearch")
ts.infile = "foo.fa"
ts.model = "var"
ts.outfile = "foo.log"
ts.debug