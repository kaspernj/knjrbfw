module Knj::Os
	def self.homedir
		if ENV["USERPROFILE"]
			homedir = ENV["USERPROFILE"]
		else
			homedir = File.expand_path("~")
		end
		
		if homedir.length <= 0
			raise "Could not figure out the homedir."
		end
		
		return homedir
	end
	
	def self.whoami
		if ENV["USERNAME"]
			whoami = ENV["USERNAME"]
		else
			whoami = %x[whoami].strip
		end
		
		if whoami.length <= 0
			raise "Could not figure out the user who is logged in."
		end
		
		return whoami
	end
	
	def self.os
		if ENV["OS"]
			teststring = ENV["OS"].to_s
		elsif (RUBY_PLATFORM)
			teststring = RUBY_PLATFORM.to_s
		end
		
		if teststring.downcase.index("windows") != nil
			return "windows"
		elsif teststring.downcase.index("linux") != nil
			return "linux"
		else
			raise "Could not figure out OS."
		end
	end
	
	def self.mode
		Php.print_r(ENV)
	end
	
	def self.class_exist(classstr)
		if Module.constants.index(classstr) != nil
			return true
		end
		
		return false
	end
	
	def self.chdir_file(filepath)
		if File.symlink?(filepath)
			Dir.chdir(File.dirname(File.readlink(filepath)))
		else
			Dir.chdir(File.dirname(filepath))
		end
	end
	
	def self.realpath(path)
		if File.symlink?(path)
			return self.realpath(File.readlink(path))
		end
		
		return path
	end
	
	#Runs a command and returns output. Also throws an exception of something is outputted to stderr.
	def self.shellcmd(cmd)
		res = {
			:out => "",
			:err => ""
		}
		
		Open3.popen3(cmd) do |stdin, stdout, stderr|
			res[:out] << stdout.read
			res[:err] << stderr.read
		end
		
		if res[:err].to_s.strip.length > 0
			raise res[:err]
		end
		
		return res[:out]
	end
	
	#Runs a command as a process of its own and wont block or be depended on this process.
	def self.subproc(cmd)
		cmd = cmd.to_s + "  >> /dev/null 2>&1 &"
		%x[#{cmd}]
	end
	
	#Returns the xauth file for GDM.
	def self.xauth_file
		authfile = ""
		Dir.new("/var/run/gdm").each do |file|
			next if file == "." or file == ".." or !file.match(/^auth-for-gdm-.+$/)
			authfile = "/var/run/gdm/#{file}/database"
		end
		
		if authfile.to_s.length <= 0
			raise "Could not figure out authfile for GDM."
		end
		
		return authfile
	end
	
	#Checks if the display variable and xauth is set - if not sets it to the GDM xauth and defaults the display to :0.0.
	def self.check_display_env
		if !ENV["DISPLAY"]
			ENV["DISPLAY"] = ":0.0"
			
			if !ENV["XAUTHORITY"]
				ENV["XAUTHORITY"] = Knj::Os.xauth_file
			end
		end
	end
end