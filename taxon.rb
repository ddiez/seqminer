# SeqMiner is a tool for mining sequence information. It aims to
# help detect sequences belonging to specific protein families.
#
# Author::    Diego Diez  (mailto:diez@kuicr.kyoto-u.ac.jp)
# Copyright:: Copyright (c) 2010
# License::   Distributes under the same terms as Ruby

require 'config'
require 'item'
require 'bio'
require 'rexml/document'
require 'ftools'

module Taxon
	include Item
	
	class Set < Set
		attr_reader :config
		def initialize(options = { :empty => false, :config => nil, :update_ncbi_info => false, :project => nil})
			super()
			
			if ! options[:config]
				@config = Config::General.new(options[:project])
			else
				@config = options[:config]
			end

			if ! options[:empty]
				tf = config.file_taxon
				file = File.open(tf)
				file.each do |line|
					next if line.match(/^#/)
					line = line.chomp
					next if line == ""
					id, name1, name2, strain, type, source = line.split("\t")
					#warn "* Taxon: " + id.to_s
	
					taxon = Taxon.new(id, name1, name2, strain, type, source)
					add(taxon)
				end
				file.close
			end
		
			load_ncbi_info(options[:update_ncbi_info])	
		end
		
		def each_taxon
			each_value do |value|
				yield value
			end
		end
		
		def get_taxon_by_name(name)
			each_value do |item|
				#warn "* searching " + name + " on " + item.name
				return item if item.name == name
			end
			return nil
		end
		
		def filter_by_name(filter)
			dt = []
			each_taxon do |taxon|
				m = false
				filter.each do |f|
					if taxon.name.match(/#{f}/)
						m = true
						break
					end
				end
				dt << taxon if ! m
			end
			dt.each do |taxon|
				delete(taxon)
			end
		end
		
		def filter_by_type(filter)
			dt = []
			each_taxon do |taxon|
				m = false
				filter.each do |f|
					if taxon.type.match(/#{f}/)
						m = true
						break
					end
				end
				dt << taxon if ! m
			end
			dt.each do |taxon|
				delete(taxon)
			end
		end
		
		def filter_by_source(filter)
			dt = []
			each_taxon do |taxon|
				m = false
				filter.each do |f|
					if taxon.source.match(/#{f}/)
						m = true
						break
					end
				end
				dt << taxon if ! m
			end
			dt.each do |taxon|
				delete(taxon)
			end
		end
		
		# This function connects to the NCBI taxonomy and gets updated information of all the taxons in the set.
		# It stores the XML file in the specified location (default: $SM_HOME/etc/ncbi_taxonomy.xml)
		def update_ncbi_info(file = nil)
			if length == 0
				warn "WARNING: no taxons in the set [skipping]"
				return -1
			end
			warn "* loading NCBI information"
			
			Bio::NCBI.default_email = "diez@kuicr.kyoto-u.ac.jp"
			ncbi = Bio::NCBI::REST::EFetch.new
			
			list = []
			each_value do |taxon|
				list << taxon.id
			end
			list.join(" ")
			taxfile = ncbi.taxonomy(list, "xml")
			
			file = config.dir_config + "ncbi_taxonomy.xml" if ! file
			# TODO: check the existence of the file and make backup.
			
			if file.exist?
				warn "* file exist! making backup..."
				File.move(file, file.dirname + (file.basename.to_s + "_ori"))
			end
			
			f = File.open(file, "w")
			f.puts taxfile
			f.close
		end
		
		# This function reads a taxonomy file from NCBI (default: $SM_HOME/etc/ncbi_taxonomy.xml) and optionally
		# forces an update.
		def load_ncbi_info(update = false)
			def _parse_ncbi_taxonomy(file)
				doc = REXML::Document.new(file.read)
				
				tax = {}
				tax['id'] = []
				tax['code'] = []
				#id = []
				#code = []
				
				doc.elements.each('TaxaSet/Taxon/TaxId') do |item|
					tax['id'] << item.text
				end
				doc.elements.each('TaxaSet/Taxon/GeneticCode/GCId') do |item|
					tax['code'] << item.text
				end
				
				#[id, code]
				tax
			end
			
			# Maybe do other way: check for each id in the TaxonSet.
			def _parse_taxonomy(tax)
				tax['id'].each_index do |index|
					taxon = get_item_by_id(tax['id'][index])
					if (! taxon.nil?) then
						taxon.trans_table = tax['code'][index].to_i
					else
						# then there is a taxon not in the file: we need to update:
						puts "WARNING: a taxon not in the ncbi taxonomy (" + tax['id'] + ") was detected. redownloading ncbi taxonomy file..."
						return nil
					end
				end
				return true
			end
			
			res1 = update_ncbi_info if update
			
			file = config.dir_config + "ncbi_taxonomy.xml"
			res1 = update_ncbi_info if ! file.exist?
			
			# OPTIONAL: maybe it is worth download the entire taxonomy? (maybe from ftp).
			return if res1 == -1 # i.e. there are no taxons in taxon.txt
			
			tax = {}
			tax = _parse_ncbi_taxonomy(file)
			res2 = _parse_taxonomy(tax)
			
			if res2.nil?
				update_ncbi_info
				tax = _parse_ncbi_taxonomy(file)
				res2 = _parse_taxonomy(tax)
				if res2.nil?
					puts "ERROR: something is wrong with the ncbi taxonomy file."
					exit
				end
			end
		end
		
		def debug
			warn "+ Taxon Set +"
			warn "* length: " + length.to_s
			each_taxon do |taxon|
				taxon.debug
			end
			warn ""
		end
	end

	class Taxon < Item
		attr_accessor :name, :strain, :binomial, :type, :source, :kegg_name, :short_name, :trans_table

		def initialize (id, name1, name2, strain, type, source)
			super(id)
			name = name1 + "." + name2
			name = name + "_" + strain if strain != ""
			@name = name
			@strain = strain
			@type = type
			@source = source
			@binomial = name1 + "." + name2
			@short_name = name1.match(/^(.)/)[0].upcase + name2
			@kegg_name = name1.match(/^(.)/)[0] + name2.match(/^(..)/)[0] + (strain == "" ? "" : "_" + strain)
			@trans_table = 1
		end
		

		def debug
			warn "+ Taxon +"
			warn "* taxon_id: " + id
			warn "* organism: " + name
			warn "* type: " + type
			warn "* source: " + source
			warn "* trans_table: " + trans_table.to_s
		end
	end
end
