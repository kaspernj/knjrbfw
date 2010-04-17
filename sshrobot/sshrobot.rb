module Knj
	class SSHRobot
		def initialize(args)
			@args = args
		end
		
		def getSession
			require "net/ssh"
			
			if (!@session)
				if (@args["port"])
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
			require "net/sftp"
			@sftp = Net::SFTP.start(@args["host"], @args["user"], @args["passwd"])
		end
		
		def shellCMD(command)
			shell = self.getShell
			result = shell.exec(command)
			cmdres = result["stdout"].slice(0..-2)
			return cmdres
		end
		
		def fileExists(filepath)
			require "knjrbfw/libstrings.rb"
			result = self.shellCMD("ls " + Strings.UnixSafe(filepath))
			
			if (result == filepath)
				return true
			else
				return false
			end
		end
	end
end