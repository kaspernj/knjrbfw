class Knj::SSHRobot
	def initialize(args)
    require "net/ssh"
    
		@forwards = []
		@args = Knj::ArrayExt.hash_sym(args)
		@args[:port] = 22 if !@args.key?(:port)
	end
	
	def session
		@session = self.session_spawn if !@session
		return @session
	end
	
	def session_spawn
		return Net::SSH.start(@args[:host], @args[:user], :password => @args[:passwd], :port => @args[:port].to_i)
	end
	
	def shell
		return self.session.shell.sync
	end
	
	def sftp
		@sftp = Net::SFTP.start(@args[:host], @args[:user], @args[:passwd], :port => @args[:port].to_i)
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
		Knj::ArrayExt.hash_sym(args)
		args[:type] = "local" if !args[:type]
		args[:session] = self.session_spawn if !args[:session]
		args[:host_local] = "0.0.0.0" if !args[:host_local]
		
		return SSHRobot::Forward.new(args)
	end
	
	alias getShell shell
	alias getSFTP sftp
	alias shellCMD exec
end

class Knj::SSHRobot::Forward
	attr_reader :open
	
	def initialize(args)
		@open = true
		@args = args
		@thread = Knj::Thread.new do
			begin
				#args[:session].logger.sev_threshold = Logger::Severity::DEBUG
				if args[:type] == "local"
					@args[:session].forward.local(@args[:host_local], @args[:port_local].to_i, @args[:host], @args[:port_remote].to_i)
				elsif args[:type] == "remote"
					@args[:session].forward.remote_to(@args[:port_local], @args[:host], @args[:port_remote], @args[:host_local])
				else
					raise "No valid type given."
				end
				
				@args[:session].loop do
					true
				end
			rescue Exception => e
				puts e.inspect
				puts e.backtrace
				
				@open = false
			end
		end
	end
	
	def close
		if !@args
			return nil
		end
		
		@args[:session].close
		@open = false
		@thread.exit
		@args = nil
		@thread = nil
	end
end