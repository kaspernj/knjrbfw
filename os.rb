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
end