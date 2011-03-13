module Knj::ArrayExt
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
			value = Knj::Php.call_user_func(args[:callback], value) if args[:callback]
			
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
		raise "Invalid argument: #{hash.class.name}" if !hash or !hash.respond_to?(:each)
		
		adds = {}
		hash.each do |key, value|
			if !key.is_a?(Symbol)
				adds[key.to_sym] = value
				hash.delete(key)
			end
		end
		
		adds.each do |key, value|
			hash[key] = value
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
	
	#Returns a hash based on the keys and values of a hash.
	def self.hash_md5(hash)
		combined_val = ""
		hash.each do |key, val|
			if combined_val.length > 0
				combined_val += ";"
			end
			
			combined_val += "#{key}:#{val}"
		end
		
		return Knj::Php.md5(combined_val)
	end
	
	#Compares the keys and values of two hashes and returns true if they are different.
	def self.hash_diff?(h1, h2, args = {})
		if !args.has_key?("h1_to_h2") or args["h1_to_h2"]
			h1.each do |key, val|
				return true if !h2.has_key?(key)
				return true if h2[key].to_s != val.to_s
			end
		end
		
		if !args.has_key?("h2_to_h1") or args["h2_to_h1"]
			h2.each do |key, val|
				return true if !h1.has_key?(key)
				return true if h1[key].to_s != val.to_s
			end
		end
		
		return false
	end
end