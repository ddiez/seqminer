

class Job
	attr_reader :id, :pid
	attr_accessor :cmd

	def initialize(id)
		@id = id
		@pid = nil
	end
	
	def run
		#puts "job id: #{id}"
		@pid = fork { system "#{cmd}" }
		#@pid = fork { sleep 5 }
	end

	def debug
		puts "* id: " + id.to_s
		puts "* cmd: " + cmd
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
		puts "* JOBS: " + length.to_s
		puts "* NCPUS: " + ncpu.to_s
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
				puts "++ Starting job #{cj + 1}"
				puts "++ " + Time.now.to_s
				job.run
				pid = job.pid
				puts "++ Job PID: #{pid}"
				
				cj+=1
				n += 1
				sj += 1
				pids[pid] = cj
			end
			if n == ncpus or sj == njobs
				cpid = Process.wait
				puts "-- Finished job #{pids[cpid]}."
				puts "-- " + Time.now.to_s
				puts "-- Job PID: #{cpid}"
				puts
				n -= 1
				fj += 1
			end
			#sleep SLEEP_TIME
		end

		ima = Time.now

		#pids.each_pair do |key,val|
		#	puts "#{val}: #{key}"
		#end
	end
end
