module Knj
	class Db_row
		def paras; return @paras; end
		def db; return @db; end
		def objects; return @paras[:objects]; end
		def is_knj?; return true; end
		
		def initialize(paras)
			@paras = paras
			@paras.each do |key, value|
				if !key.is_a?(Symbol)
					@paras[key.to_sym] = value
					@paras.delete(key)
				end
			end
			
			if !@paras[:db] and $db and $db.class.to_s == "Knj::Db"
				@paras[:db] = $db
			end
			
			if !@paras[:objects] and $objects and $objects.class.to_s == "Knj::Objects"
				@paras[:objects] = $objects
			end
			
			@db = @paras[:db]
			
			if !@paras[:col_id]
				@paras[:col_id] = :id
			end
			
			if !@paras[:table]
				raise "No table given."
			end
			
			if @paras[:data] and (@paras[:data].is_a?(Integer) or @paras[:data].is_a?(Fixnum) or @paras[:data].is_a?(String))
				@data = {@paras[:col_id].to_sym => @paras[:data].to_s}
				self.reload
			elsif @paras[:data] and @paras[:data].is_a?(Hash)
				@data = @paras[:data]
				@data.each do |key, value|
					if !key.is_a?(Symbol)
						@data[key.to_sym] = value
						@data.delete(key)
					end
				end
			elsif @paras[:id]
				@data = {}
				@data[@paras[:col_id].to_sym] = @paras[:id]
				self.reload
			else
				raise Knj::Errors::InvalidData.new("Invalid data: #{@paras[:data].to_s} (#{@paras[:data].class.to_s})")
			end
		end
		
		def reload
			last_id = self.id
			@data = @db.single(@paras[:table], {@paras[:col_id] => self.id})
			if !@data
				raise Knj::Errors::NotFound.new("Could not find any data for the object with ID: '#{last_id}' in the table '#{@paras[:table].to_s}'.")
			end
			
			@data.each do |key, value|
				if !key.is_a?(Symbol)
					@data[key.to_sym] = value
					@data.delete(key)
				end
			end
		end
		
		def update(newdata)
			@db.update(@paras[:table], newdata, {@paras[:col_id] => self.id})
			self.reload
			
			if self.objects
				self.objects.call("object" => self, "signal" => "update")
			end
		end
		
		def delete
			@db.delete(@paras[:table], {@paras[:col_id] => self.id})
			self.destroy
		end
		
		def destroy
			@paras = nil
			@db = nil
			@data = nil
		end
		
		def has_key?(key)
			return @data.has_key?(key.to_sym)
		end
		
		def [](key)
			if !key
				raise "No valid key given."
			end
			
			if !@data.has_key?(key.to_sym)
				raise "No such key: #{key.to_s}."
			end
			
			return @data[key.to_sym]
		end
		
		def []=(key, value)
			self.update(key.to_sym => value)
			self.reload
		end
		
		def data
			return @data
		end
		
		def id
			return @data[@paras[:col_id]]
		end
		
		def title
			if @paras[:col_title]
				return @data[@paras[:col_title].to_sym]
			end
			
			if @data.has_key?(:title)
				return @data[:title]
			elsif @data.has_key?(:name)
				return @data[:name]
			end
			
			raise "'col_title' has not been set for the class: '#{self.class.to_s}'."
		end
		
		def each(&paras)
			return @data.each(&paras)
		end
		
		def method_missing(*args)
			func_name = args[0].to_s
			if match = func_name.match(/^(\S+)\?$/) and @data.has_key?(match[1])
				if @data[match[1].to_sym] == "1" or @data[match[1].to_sym] == "yes"
					return true
				elsif @data[match[1].to_sym] == "0" or @data[match[1].to_sym] == "no"
					return false
				end
			end
			
			raise sprintf("No such method: %s", func_name)
		end
	end
end