module Knj
	class Strings
		def self.UnixSafe(tha_string)
			tha_string = tha_string.gsub(" ", "\ ").gsub("&", "\&")
			return tha_string
		end
	end
end