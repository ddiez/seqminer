#!/usr/bin/env ruby
#
# SeqMiner is a tool for mining sequence information. It aims to
# help detect sequences belonging to specific protein families.
#
# Author::    Diego Diez  (mailto:diez@kuicr.kyoto-u.ac.jp)
# Copyright:: Copyright (c) 2010
# License::   Distributes under the same terms as Ruby

require 'seqminer'

# 1.1 create pipelie object.
sm = SeqMiner::Pipeline.new("vardb-dr-6")

# 1.2 optional: filter taxons.
sm.taxon.filter_by_name("bordetella")
#sm.taxon.filter_by_type("spp")
sm.taxon.debug

# 1.3 optional: filter families.
sm.ortholog.filter_by_name("prn")
sm.ortholog.debug

## run all.
# 2.1 run search, get results, write reports, run scan, get results, write reports.
#sm.run_all

## run step by step (instead of run_all above)
# 2.2 optional: search
sm.build_search
#sm.run_search
sm.get_search_results
sm.write_nelson
#sm.write_fasta

# 2.3 optional: scan (requires search above)
#sm.build_scan
#sm.run_scan
#sm.get_scan_results
#sm.write_domain

# 3.1 report
# TODO: check all the reports.
# TODO: report to vardb dir.
#sm.build_search
#sm.get_search_results(eval = 0.01)
#sm.report
#sm.report(0.8)
#sm.report_summary