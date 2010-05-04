module Knj
	module ArrayExt
		def self.join(arr, key, sep)
			str = ""
			first = true
			
			arr.each do |value|
				if first
					first = false
				else
					str += sep
				end
				
				str += value[key]
			end
			
			return str
		end
	end
end