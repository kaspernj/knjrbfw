module Knj
	module Strings
		def self.UnixSafe(tha_string)
			return tha_string.to_s.gsub(" ", "\ ").gsub("&", "\&")
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
	end
end