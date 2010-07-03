module Knj
	class SSHRobot
		def initialize(args)
			@args = args
			
			if !@args["port"]
				@args["port"] = 22
			end
		end
		
		def getSession
			if !@session
				if @args["port"]
					@session = Net::SSH.start(@args["host"], @args["port"].to_i, @args["user"], @args["passwd"])
				else
					@session = Net::SSH.start(@args["host"], @args["user"], @args["passwd"])
				end
			end
			
			return @session
		end
		
		def getShell
			return getSession.shell.sync
		end
		
		def getSFTP
			@sftp = Net::SFTP.start(@args["host"], @args["user"], @args["passwd"])
		end
		
		def shellCMD(command)
			shell = self.getShell
			result = shell.exec(command)
			cmdres = result["stdout"].slice(0..-2)
			return cmdres
		end
		
		def fileExists(filepath)
			result = self.shellCMD("ls " + Knj::Strings.UnixSafe(filepath))
			
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
		
		alias session getSession
		alias shell getShell
		alias sftp getSFTP
	end
end