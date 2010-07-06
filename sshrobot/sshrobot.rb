module Knj
	class SSHRobot
		def initialize(args)
			@args = args
			
			if !@args.has_key?("port")
				@args["port"] = 22
			end
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
		
		def forward(paras)
			if !paras["type"]
				paras["type"] = "local"
			end
			
			if !paras["session"]
				paras["session"] = self.session
			end
			
			if !paras["host_local"]
				paras["host_local"] = "0.0.0.0"
			end
			
			if paras["type"] == "local"
				paras["session"].forward.local(paras["port_local"].to_i, paras["host_local"], paras["port_remote"], paras["host"])
			else
				raise "No valid type given."
			end
		end
		
		alias getShell shell
		alias getSFTP sftp
		alias shellCMD exec
	end
end