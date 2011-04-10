class Knj::Datarow
	attr_reader :data, :ob
	
	def is_knj?; return true; end
	
	def self.table
		return self.name.split("::").last
	end
	
	def table
		return self.class.name.split("::").last
	end
	
	def initialize(d)
		@ob = d.ob
		raise "No ob given." if !@ob
		
		if d.data.is_a?(Hash)
			@data = d.data
		elsif d.data
			@data = {:id => d.data}
			self.reload
		else
			Knj::Php.print_r(args)
			raise "Could not figure out the data."
		end
	end
	
	def db
		return @ob.db
	end
	
	def reload
		data = self.db.single(self.table, {:id => @data[:id]})
		if !data
			raise Knj::Errors::NotFound.new("Could not find any data for the object with ID: '#{@data[:id]}' in the table '#{self.table}'.")
		end
		
		@data = data
	end
	
	def update(newdata)
		self.db.update(self.table, newdata, {:id => @data[:id]})
		self.reload
		
		if self.ob
			self.ob.call("object" => self, "signal" => "update")
		end
	end
	
	def delete
		self.db.delete(self.table, {:id => @data[:id]})
		self.destroy
	end
	
	def destroy
		@ob = nil
		@data = nil
	end
	
	def has_key?(key)
		return @data.has_key?(key.to_sym)
	end
	
	def [](key)
		raise "No valid key given." if !key
		raise "No data was loaded on the object? Maybe you are trying to call a deleted object?" if !@data
		return @data[key] if @data.has_key?(key)
		raise "No such key: #{key.to_s}."
	end
	
	def []=(key, value)
		self.update(key.to_sym => value)
		self.reload
	end
	
	def id
		return @data[:id]
	end
	
	def name
		if @data.has_key?(:title)
			return @data[:title]
		elsif @data.has_key?(:name)
			return @data[:name]
		end
		
		Knj::Php.print_r(@data)
		
		raise "Couldnt figure out the title/name of the object on class #{self.class.name}."
	end
	
	alias :title :name
	
	def each(&args)
		return @data.each(&args)
	end
	
	def method_missing(*args)
		func_name = args[0].to_s
		if match = func_name.match(/^(\S+)\?$/) and @data.has_key?(match[1].to_sym)
			if @data[match[1].to_sym] == "1" or @data[match[1].to_sym] == "yes"
				return true
			elsif @data[match[1].to_sym] == "0" or @data[match[1].to_sym] == "no"
				return false
			end
		end
		
		raise sprintf("No such method: %s", func_name)
	end
end