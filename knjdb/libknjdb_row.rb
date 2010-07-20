module Knj
	class Db_row
		def paras; return @paras; end
		def db; return @db; end
		def objects; return @paras["objects"]; end
		def is_knj?; return true; end
		
		def initialize(paras)
			@paras = paras
			
			if !@paras["db"] and $db and $db.class.to_s == "Knj::Db"
				@paras["db"] = $db
			end
			
			if !@paras["objects"] and $objects and $objects.class.to_s == "Knj::Objects"
				@paras["objects"] = $objects
			end
			
			if !@paras["objects"] and $ob and $ob.class.to_s == "Knj::Objects"
				@paras["objects"] = $ob
			end
			
			@db = @paras["db"]
			
			if !@paras["col_id"]
				@paras["col_id"] = "id"
			end
			
			if !@paras["table"]
				raise "No table given."
			end
			
			if @paras["data"] and (@paras["data"].is_a?(Integer) or @paras["data"].is_a?(Fixnum) or @paras["data"].is_a?(String))
				@data = {@paras["col_id"] => @paras["data"].to_s}
				self.reload
			elsif @paras["data"] and @paras["data"].is_a?(Hash)
				@data = @paras["data"]
			elsif @paras["id"]
				@data = {}
				@data[@paras["col_id"]] = @paras["id"]
				self.reload
			else
				raise "Invalid data: " + @paras["data"].to_s + " (" + @paras["data"].class.to_s + ")"
			end
		end
		
		def reload
			last_id = self.id
			@data = @db.single(@paras["table"], {@paras["col_id"] => self.id})
			if !@data
				raise "Could not find any data for the object with ID: '" + last_id + "' in the table '" + @paras["table"] + "'."
			end
		end
		
		def update(newdata)
			@db.update(@paras["table"], newdata, {@paras["col_id"] => self.id})
			self.reload
			
			if self.objects
				self.objects.call("object" => self, "signal" => "update")
			end
		end
		
		def delete
			@db.delete(@paras["table"], {@paras["col_id"] => self.id})
			self.destroy
		end
		
		def destroy
			@paras = nil
			@db = nil
			@data = nil
		end
		
		def has_key?(key)
			return @data.has_key?(key)
		end
		
		def [](key)
			if !key
				raise "No valid key given."
			end
			
			if !@data.has_key?(key)
				raise "No such key: " + key
			end
			
			return @data[key]
		end
		
		def []=(key, value)
			self.update(key => value)
			self.reload
		end
		
		def data
			return @data
		end
		
		def id
			return @data[@paras["col_id"]]
		end
		
		def title
			if !@paras["col_title"]
				raise "'col_title' has not been set for the class: '" + self.class.to_s + "'."
			end
			
			return @data[@paras["col_title"]]
		end
		
		def each(&paras)
			return @data.each(&paras)
		end
	end
end