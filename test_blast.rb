require 'tools'

#t = Tools::Blast.new
#t.tool = "blastall"
#t.pssm_file = "foo.pssm"
#t.seed_file = "foo.seed"
#t.db = "cds"
#t.outfile = "test_blastall.txt"
#t.debug
#t.execute

require 'result'

ts = Taxon::Set.new
t = ts.get_taxon_by_name("anaplasma.marginale_st_maries")

os = Ortholog::Set.new
o = os.get_ortholog_by_name("msp2_p44_map1_omp")


rp = Result::BlastParser.new(options = {:taxon => t, :ortholog => o})
rp.result_id = "foo"
rp.type = "clade"
rp.file = "test_blast.txt"
r = rp.parse
r.debug
r.filter_by_eval(0.001)
r.debug
r.export_nelson