class Knj::Hash_methods
	def initialize(data)
		@data = data
	end
	
	def [](key)
		return @data[key]
	end
	
	def db
		return @data[:db]
	end
	
	def ob
		return @data[:ob]
	end
	
	def args
		return @data[:args]
	end
	
	def data
		return @data[:data]
	end
	
	def method_missing(method, *paras)
		if !@data.has_key?(method)
			raise "No such method '#{method}' on class '#{self.class.name}'"
		end
		
		return @data[method.to_sym]
	end
end