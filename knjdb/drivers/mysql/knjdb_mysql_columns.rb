class KnjDB_mysql::Columns
	attr_reader :db, :driver
	
	def initialize(args)
		@args = args
		@db = @args[:db]
		@driver = @args[:driver]
	end
	
	def data_sql(name, data)
		raise "No type given." if !data["type"]
		
		if data["type"] == "varchar" and !data.has_key?("maxlength")
			data["maxlength"] = 255
		end
		
		sql = "`#{name}` #{data["type"]}"
		
		if data["maxlength"]
			sql += "(#{data["maxlength"]})"
		end
		
		if data["primarykey"]
			sql += " PRIMARY KEY"
		end
		
		if data["autoincr"]
			sql += " AUTO_INCREMENT"
		end
		
		if !data["null"]
			sql += " NOT NULL"
		end
		
		if data["default"]
			sql += " DEFAULT '#{@db.sql(data["default"])}'"
		end
		
		return sql
	end
end

class KnjDB_mysql::Columns::Column
	attr_reader :args
	
	def initialize(args)
		@args = args
		@db = @args[:db]
	end
	
	def name
		return @args[:data][:Field]
	end
	
	def type
		if match = @args[:data][:Type].match(/^(.+)\((\d+)\)$/)
			@maxlength = match[2]
			return match[1]
		end
		
		return @args[:data][:Type]
	end
	
	def null?
		return false if @args[:data][:Null] == "NO"
		return true
	end
	
	def maxlength
		self.type
		return @maxlength if @maxlength
		return false
	end
	
	def default
		return false if !@args[:data][:Default]
		return @args[:data][:Default]
	end
	
	def drop
		sql = "ALTER TABLE `#{@args[:table].name}` DROP COLUMN `#{self.name}`"
		@args[:db].query(sql)
	end
	
	def change(data)
		esc_col = @args[:driver].escape_col
		col_escaped = "#{esc_col}#{@db.esc_col(self.name)}#{esc_col}"
		table_escape = "#{@args[:driver].escape_table}#{@args[:driver].esc_table(@args[:table].name)}#{@args[:driver].escape_table}"
		newdata = data.clone
		
		newdata["name"] = self.name if !newdata.has_key?("name")
		newdata["type"] = self.type if !newdata.has_key?("type")
		newdata["maxlength"] = self.maxlength if !newdata.has_key?("maxlength") and self.maxlength
		newdata["null"] = self.null? if !newdata.has_key?("null")
		newdata["default"] = self.default if !newdata.has_key?("default")
		
		if newdata.has_key?("primarykey")
			newdata.delete("primarykey")
		end
		
		type_s = newdata["type"].to_s
		
		sql = "ALTER TABLE #{table_escape} CHANGE #{col_escaped} #{@db.cols.data_sql(newdata["name"], newdata)}"
		
		print "SQL: #{sql}\n"
		
		@db.query(sql)
	end
end