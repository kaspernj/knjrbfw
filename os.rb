module Knj
	module Os
		def homedir
			if (ENV["USERPROFILE"])
				homedir = ENV["USERPROFILE"]
			else
				homedir = File.expand_path("~")
			end
			
			if (homedir.length <= 0)
				raise "Could not figure out the homedir."
			end
			
			return homedir
		end
		
		def whoami
			if (ENV["USERNAME"])
				whoami = ENV["USERNAME"]
			else
				whoami = %x[whoami].strip
			end
			
			if (whoami.length <= 0)
				raise "Could not figure out the user who is logged in."
			end
			
			return whoami
		end
		
		def os
			if (ENV["OS"])
				teststring = ENV["OS"].to_s
			elsif (RUBY_PLATFORM)
				teststring = RUBY_PLATFORM.to_s
			end
			
			if (teststring.downcase.index("windows") != nil)
				return "windows"
			elsif (teststring.downcase.index("linux") != nil)
				return "linux"
			else
				raise "Could not figure out OS."
			end
		end
	end
end