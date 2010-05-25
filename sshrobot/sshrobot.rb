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
		
		def getSFTP
			@sftp = Net::SFTP.start(@args["host"], @args["user"], @args["passwd"], :port => @args["port"].to_i)
		end
		
		def shellCMD(command)
			return self.session.exec!(command)
		end
		
		def fileExists(filepath)
			result = self.shellCMD("ls " + Strings.UnixSafe(filepath))
			
			if result == filepath
				return true
			else
				return false
			end
		end
		
		alias getSession session
		alias getShell shell
		alias exec shellCMD
	end
end