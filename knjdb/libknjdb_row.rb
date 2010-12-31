class Knj::Db_row
	attr_reader :args
	
	def objects; return @args[:objects]; end
	def is_knj?; return true; end
	
	def initialize(args)
		@args = {}
		args.each do |key, value|
			@args[key.to_sym] = value
		end
		
		@args[:db] = $db if !@args[:db] and $db and $db.class.to_s == "Knj::Db"
		@args[:objects] = $objects if !@args[:objects] and $objects and $objects.class.to_s == "Knj::Objects"
		@args[:col_id] = :id if !@args[:col_id]
		raise "No table given." if !@args[:table]
		
		if @args[:data] and (@args[:data].is_a?(Integer) or @args[:data].is_a?(Fixnum) or @args[:data].is_a?(String))
			@data = {@args[:col_id].to_sym => @args[:data].to_s}
			self.reload
		elsif @args[:data] and @args[:data].is_a?(Hash)
			@data = {}
			@args[:data].each do |key, value|
				@data[key.to_sym] = value
			end
		elsif @args[:id]
			@data = {}
			@data[@args[:col_id].to_sym] = @args[:id]
			self.reload
		else
			raise Knj::Errors::InvalidData.new("Invalid data: #{@args[:data].to_s} (#{@args[:data].class.to_s})")
		end
	end
	
	def db
		if !@args[:force_selfdb]
			curthread = Thread.current
			if curthread.is_a?(Knj::Thread) and curthread[:knjappserver] and curthread[:knjappserver][:db]
				return curthread[:knjappserver][:db]
			end
		end
		
		return @args[:db]
	end
	
	def reload
		last_id = self.id
		data = self.db.single(@args[:table], {@args[:col_id] => self.id})
		if !data
			raise Knj::Errors::NotFound.new("Could not find any data for the object with ID: '#{last_id}' in the table '#{@args[:table].to_s}'.")
		end
		
		@data = {}
		data.each do |key, value|
			@data[key.to_sym] = value
		end
	end
	
	def update(newdata)
		self.db.update(@args[:table], newdata, {@args[:col_id] => self.id})
		self.reload
		
		if self.objects
			self.objects.call("object" => self, "signal" => "update")
		end
	end
	
	def delete
		self.db.delete(@args[:table], {@args[:col_id] => self.id})
		self.destroy
	end
	
	def destroy
		@args = nil
		@data = nil
	end
	
	def has_key?(key)
		return @data.has_key?(key.to_sym)
	end
	
	def [](key)
		raise "No valid key given." if !key
		
		if @data.has_key?(key)
			return @data[key]
		elsif @data.has_key?(key.to_sym)
			return @data[key.to_sym]
		elsif @data.has_key?(key.to_s)
			return @data[key.to_s]
		end
		
		raise "No such key: #{key.to_s}."
	end
	
	def []=(key, value)
		self.update(key.to_sym => value)
		self.reload
	end
	
	def data
		return @data
	end
	
	def id
		return @data[@args[:col_id]]
	end
	
	def title
		if @args[:col_title]
			return @data[@args[:col_title].to_sym]
		end
		
		if @data.has_key?(:title)
			return @data[:title]
		elsif @data.has_key?(:name)
			return @data[:name]
		end
		
		raise "'col_title' has not been set for the class: '#{self.class.to_s}'."
	end
	
	alias :name :title
	
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