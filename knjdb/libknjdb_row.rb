module Knj
	class Db_row
		def paras; return @paras; end
		def db; return @db; end
		def objects; return @objects; end
		
		def initialize(paras)
			@paras = paras
			@db = @paras["db"]
			@table = @paras["table"]
			@objects = @paras["objects"]
			
			if (!@paras["col_id"])
				@paras["col_id"] = "id"
			end
			
			if (@paras["data"] and (@paras["data"].class.to_s == "Integer" or @paras["data"].class.to_s == "Fixnum" or @paras["data"].class.to_s == "String"))
				@data = {"id" => @paras["data"].to_s}
				self.reload
			elsif(@paras["data"] and @paras["data"].class.to_s == "Hash")
				@data = @paras["data"]
			elsif(@paras["id"])
				@data = {}
				@data["id"] = @paras["id"]
				self.reload
			else
				raise "Invalid data: " + @paras["data"] + " (" + @paras["data"].class.to_s + ")"
			end
		end
		
		def reload
			last_id = @data["id"]
			@data = @db.single(@paras["table"], {@paras["col_id"] => @data["id"]})
			if (!@data)
				raise "Could not find any data for the object with ID: '" + last_id + "' in the table '" + @table + "'."
			end
		end
		
		def update(newdata)
			@db.update(@paras["table"], newdata, {@paras["col_id"] => @data["id"]})
			self.reload
		end
		
		def delete
			@db.delete(@paras["table"], {@paras["col_id"] => @data["id"]})
			self.destroy
		end
		
		def destroy
			@paras = nil
			@db = nil
			@data = nil
			@table = nil
		end
		
		def [](key)
			if (!key)
				raise "No valid key given."
			end
			
			if (!@data.has_key?(key))
				raise "No such key: " + key
			end
			
			return @data[key]
		end
		
		def []=(key, value)
			self.update({key => value})
			self.reload
		end
		
		def data
			return @data
		end
		
		def each(&paras)
			return @data.each(&paras)
		end
	end
end