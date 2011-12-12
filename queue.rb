# queue.rb
#
# Description: this modules enables to create a queue useful to send multiple jobs
#   in multicore or multiple CPU environments. It is a very simple implementation
#   and so it does not consider other users and/or processes. Uses sensible ncpu
#   parameters for your system.
#
# Author: Diego Diez
# Contact: diego10ruiz@gmail.com
# Licence: GPL3
#
# Usage:
#

class Job
	attr_reader :id, :pid
	attr_accessor :cmd

	def initialize(id)
		@id = id
		@pid = nil
	end
	
	def run
		#warn "job id: #{id}"
		@pid = fork { system "#{cmd}" }
		#@pid = fork { sleep 5 }
	end

	def debug
		warn "* id: " + id.to_s
		warn "* cmd: " + cmd
	end
end

class Queue
	attr_reader :jobs, :length
	attr_accessor :ncpu

	SLEEP_TIME = 2
	def initialize
		@ncpu = 5
		@jobs = []
	end

	def << j
		@jobs << j
	end

	def length
		jobs.length
	end

	def debug
		warn "* JOBS: " + length.to_s
		warn "* NCPUS: " + ncpu.to_s
		jobs.each do |j|
			j.debug
		end
	end

	def run
		njobs = self.length
		ncpus = self.ncpu
		cj = 0 # current job number already launched.
		sj = 0 # number of started jobs
		fj = 0 # number of finished jobs
		n = 0 # number of current processes running.
		pids = Hash.new
		while fj < njobs do
			if n < ncpus and sj < njobs
				#job = Job.new(cj)
				#job.cmd = jobs[job.id]
				job = @jobs[cj]
				warn "++ Starting job #{cj + 1}"
				warn "++ " + Time.now.to_s
				job.run
				pid = job.pid
				warn "++ Job PID: #{pid}"
				
				cj+=1
				n += 1
				sj += 1
				pids[pid] = cj
			end
			if n == ncpus or sj == njobs
				cpid = Process.wait
				warn "-- Finished job #{pids[cpid]}."
				warn "-- " + Time.now.to_s
				warn "-- Job PID: #{cpid}\n"
				n -= 1
				fj += 1
			end
			#sleep SLEEP_TIME
		end

		ima = Time.now

		#pids.each_pair do |key,val|
		#	warn "#{val}: #{key}"
		#end
	end
end
