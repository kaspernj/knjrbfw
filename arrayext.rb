module Knj
	module ArrayExt
		def self.join(args = {}, key = nil, sep = nil)
			if args.is_a?(Array) and sep
				args = {
					:arr => args,
					:sep => sep,
					:key => key
				}
			end
			
			str = ""
			first = true
			
			args[:arr].each do |value|
				if first
					first = false
				else
					str += args[:sep]
				end
				
				value = value[key] if args[:key]
				value = value if !args[:key]
				value = Php.call_user_func(args[:callback], value) if args[:callback]
				
				if args[:callback] and !value
					raise "Callback returned nothing."
				end
				
				str += args[:surr] if args[:surr]
				str += value.to_s
				str += args[:surr] if args[:surr]
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
		
		#Converts all keys in the given hash to symbols.
		def self.hash_sym(hash)
			hash.each do |key, value|
				if !key.is_a?(Symbol)
					hash[key.to_sym] = value
					hash.delete(key)
				end
			end
			
			return hash
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