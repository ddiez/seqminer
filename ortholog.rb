# SeqMiner is a tool for mining sequence information. It aims to
# help detect sequences belonging to specific protein families.
#
# Author::    Diego Diez  (mailto:diez@kuicr.kyoto-u.ac.jp)
# Copyright:: Copyright (c) 2010
# License::   Distributes under the same terms as Ruby

require 'config'
require 'item'

module Ortholog
	include Item

	class Set < Set
		include Common
		attr_reader :config, :file_log
		def initialize(options = {:empty => false, :config => nil})
			super()

			if ! options[:config]
				@config = Config::General.new(options[:project])
			else
				@config = options[:config]
			end
			@file_log = config.file_log
			
			if ! options[:empty]
				of = config.file_ortholog
				file = File.open(of)
				file.each do |line|
					line = line.chomp
					next if line == ""
					next if line =~ /^#/
					name, hmm = line.split("\t")
					#info "* Ortholog: " + name
	
					ortholog = Ortholog.new(name, hmm)
					ortholog.file_log = file_log
					self.add(ortholog)
				end
				file.close
			end
		end
		
		def each_ortholog
			each_value do |value|
				yield value
			end
		end
		
		def get_ortholog_by_name(name)
			each_ortholog do |o|
				return o if o.name == name
			end
			return nil
		end
		
		def filter_by_name(filter)
			dor = []
			each_ortholog do |ortholog|
				m = false
				filter.each do |f|
					if ortholog.name.match(/#{f}/)
						m = true
						break
					end
				end
				dor << ortholog if ! m
			end
			dor.each do |i|
				delete(i)
			end
		end

		def debug
			info "+ Ortholog Set+"
			info "* length: " + length.to_s
			each_value do |ortholog|
				ortholog.debug
			end
			info
		end
	end

	class Ortholog < Item
		include Common
		attr_accessor :hmm, :name, :file_log

		def initialize (name, hmm)
			super(name.to_s + "." + hmm.to_s)
			@name = name
			@hmm = hmm
		end
		
		def file_log=(file)
			@file_log = file
		end

		def debug
			info "+ Ortholog +"
			info "* id: " + id
			info "* name: " + name
			info "* hmm: " + hmm
		end
	end
end
