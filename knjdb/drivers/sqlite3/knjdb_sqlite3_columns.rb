class KnjDB_sqlite3::Columns
	attr_reader :db, :driver
	
	def initialize(args)
		@args = args
		@db = @args[:db]
		@driver = @args[:driver]
	end
	
	def data_sql(data)
		raise "No type given." if !data["type"]
		
		data["maxlength"] = 255 if data["type"] == "varchar" and !data.has_key?("maxlength")
		data["type"] = "integer" if data["type"] == "int"
		
		sql = "`#{data["name"]}` #{data["type"]}"
		sql += "(#{data["maxlength"]})" if data["maxlength"] and !data["autoincr"]
		sql += "(11)" if !data.has_key?("maxlength") and !data["autoincr"]
		sql += " PRIMARY KEY" if data["primarykey"]
		sql += " NOT NULL" if !data["null"] and data.has_key?("null")
		
		if data.has_key?("default_func")
			sql += " DEFAULT #{data["default_func"]}"
		elsif data.has_key?("default") and data["default"] != false
			sql += " DEFAULT '#{@driver.escape(data["default"])}'"
		end
		
		sql += " COMMENT '#{@driver.escape(data["comment"])}'" if data.has_key?("comment")
		
		return sql
	end
end

class KnjDB_sqlite3::Columns::Column
	attr_reader :args
	
	def initialize(args)
		@args = args
		@db = @args[:db]
	end
	
	def name
		return @args[:data][:name]
	end
	
	def table
		return @args[:table]
	end
	
	def data
		return {
			"type" => self.type,
			"name" => self.name,
			"null" => self.null?,
			"maxlength" => self.maxlength,
			"default" => self.default,
			"primarykey" => self.primarykey?,
			"autoincr" => self.autoincr?
		}
	end
	
	def type
		if !@type
			if match = @args[:data][:type].match(/^([A-z]+)$/)
				@maxlength = false
				type = match[0]
			elsif match = @args[:data][:type].match(/^decimal\((\d+),(\d+)\)$/)
				@maxlength = "#{match[1]},#{match[2]}"
				type = "decimal"
			elsif match = @args[:data][:type].match(/^enum\((.+)\)$/)
				@maxlength = match[1]
				type = "enum"
			elsif match = @args[:data][:type].match(/^(.+)\((\d+)\)$/)
				@maxlength = match[2]
				type = match[1]
			end
			
			if type == "integer"
				@type = "int"
			else
				@type = type
			end
		end
		
		return @type
	end
	
	def null?
		return false if @args[:data][:notnull].to_i == 1
		return true
	end
	
	def maxlength
		self.type
		return @maxlength if @maxlength
		return false
	end
	
	def default
		def_val = @args[:data][:dflt_value]
		if def_val.to_s.slice(0..0) == "'"
			def_val = def_val.to_s.slice(0)
		end
		
		if def_val.to_s.slice(-1..-1) == "'"
			def_val = def_val.to_s.slice(0, def_val.length - 1)
		end
		
		return false if @args[:data][:dflt_value].to_s.length == 0
		return def_val
	end
	
	def primarykey?
		return false if @args[:data][:pk].to_i == 0
		return true
	end
	
	def autoincr?
		print "Autoincr:\n"
		Knj::Php.print_r(@args[:data])
		return false
	end
	
	def drop
		@args[:table].copy(
			"drops" => self.name
		)
	end
	
	def change(data)
		newdata = data.clone
		
		newdata["name"] = self.name if !newdata.has_key?("name")
		newdata["type"] = self.type if !newdata.has_key?("type")
		newdata["maxlength"] = self.maxlength if !newdata.has_key?("maxlength") and self.maxlength
		newdata["null"] = self.null? if !newdata.has_key?("null")
		newdata["default"] = self.default if !newdata.has_key?("default")
		newdata.delete("primarykey") if newdata.has_key?("primarykey")
		
		new_table = self.table.copy(
			"alter_columns" => {
				self.name.to_s => newdata
			}
		)
	end
end