class Knj::Unix_proc
	attr_reader :data
	@procs = {}
	
	def self.spawn(data)
		proc = @procs[data["pid"]]
		
		if proc
			proc.update_data(data)
		else
			@procs[data["pid"]] = Knj::Unix_proc.new(data)
		end
		
		return @procs[data["pid"]]
	end
	
	def self.list(args = {})
		cmdstr = "ps aux"
		grepstr = ""
		
		if args["grep"]
			grepstr = "grep #{Knj::Strings.unixsafe(args["grep"])}"
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
			
			if match[1].to_i != $$.to_i
				if !grepstr or match[4].index(grepstr) == nil   #dont return current process.
					ret << Knj::Unix_proc.spawn(data)
				end
			end
		end
		
		return ret
	end
	
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