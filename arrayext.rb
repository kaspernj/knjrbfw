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
		
		def self.hash(arr)
			ret = {}
			arr.each do |item|
				ret[ret.length.to_s] = item
			end
			
			return ret
		end
		
		def self.dict(arr)
			ret = Dictionary.new
			arr.each do |item|
				ret[ret.length.to_s] = item
			end
			
			return ret
		end
	end
end