require 'Tools'

ts = Tools::Blast.new
ts.tool = "makeblastdb"
ts.db = "cds"
ts.dbtype = "nucl"
ts.dbtitle = "CDS from my species"
ts.infile = "cds.fa"
ts.debug
