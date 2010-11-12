class Knj::Unix_proc
	@procs = {}
	
	def self.spawn(data)
		proc = @procs[data["pid"]]
		
		if proc
			proc.update_data(data)
		else
			@procs[data["pid"]] = Unix_proc.new(data)
		end
		
		return @procs[data["pid"]]
	end
	
	def self.list(paras = {})
		cmdstr = "ps aux"
		grepstr = ""
		
		if paras["grep"]
			grepstr = "grep #{Strings.unixsafe(paras["grep"])}"
			cmdstr += " | #{grepstr}"
		end
		
		ret = []
		res = %x[#{cmdstr}]
		
		res.scan(/^(\S+)\s+([0-9]+)\s+([0-9.]+)\s+([0-9.]+)\s+\S+\s+\S+\s+\S+\s+\S+\s+\S+\s+\S+ (.+)($|\n)/) do |match|
			data = {
				"user" => match[0],
				"pid" => match[1],
				"cpu_last" => match[2],
				"ram_last" => match[3],
				"cmd" => match[4],
				"app" => File.basename(match[4])
			}
			
			if match[1] != $$
				if !grepstr or match[4].index(grepstr) == nil   #dont return current process.
					ret << Unix_proc.spawn(data)
				end
			end
		end
		
		return ret
	end
	
	attr_reader :data
	
	def initialize(data)
		@data = data
	end
	
	def [](key)
		raise "No such data: #{key}" if !@data.has_key?(key)
		return @data[key]
	end
	
	def kill
		Process.kill(9, @data["pid"].to_i)
	end
end