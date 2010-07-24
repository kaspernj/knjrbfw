module Knj
	module Strings
		def self.UnixSafe(tha_string)
			return tha_string.to_s.gsub(" ", "\\ ").gsub("&", "\&").gsub("(", "\\(").gsub(")", "\\)").gsub('"', '\"').gsub("\n", "\"\n\"")
		end
		
		def self.unixsafe(string)
			return Strings.UnixSafe(string)
		end
		
		def self.searchstring(string)
			words = []
			string = string.to_s
			
			matches = string.scan /(\"(.+?)\")/
			matches.each do |matcharr|
				word = matcharr[1]
				
				if word and word.length > 0
					words << matcharr[1]
					string = string.gsub(matcharr[0], "")
				end
			end
			
			string.split(/\s/).each do |word|
				if word and word.length > 0
					words << word
				end
			end
			
			return words
		end
		
		def self.is_email?(str)
			if str.match(/^\S+@\S+.\S+$/)
				return true
			end
			
			return false
		end
		
		def self.js_safe(str)
			return str.gsub("\r", "").gsub("\n", "\\n").gsub('"', '\"');
		end
	end
end