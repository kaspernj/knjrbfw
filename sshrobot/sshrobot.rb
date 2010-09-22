class Knj::SSHRobot
	def initialize(args)
		@args = args
		@args["port"] = 22 if !@args.has_key?("port")
	end
	
	def session
		if !@session
			@session = Net::SSH.start(@args["host"], @args["user"], :password => @args["passwd"], :port => @args["port"].to_i)
		end
		
		return @session
	end
	
	def shell
		return self.session.shell.sync
	end
	
	def sftp
		@sftp = Net::SFTP.start(@args["host"], @args["user"], @args["passwd"], :port => @args["port"].to_i)
	end
	
	def exec(command)
		return self.session.exec!(command)
	end
	
	def fileExists(filepath)
		result = self.exec("ls " + Strings.UnixSafe(filepath)).strip
		
		if result == filepath
			return true
		else
			return false
		end
	end
	
	def forward(args)
		args["type"] = "local" if !args["type"]
		args["session"] = self.session if !args["session"]
		args["host_local"] = "0.0.0.0" if !args["host_local"]
		
		if args["type"] == "local"
			args["session"].forward.local(args["port_local"].to_i, args["host_local"], args["port_remote"], args["host"])
		else
			raise "No valid type given."
		end
	end
	
	alias getShell shell
	alias getSFTP sftp
	alias shellCMD exec
end