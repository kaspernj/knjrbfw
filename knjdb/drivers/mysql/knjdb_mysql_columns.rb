class KnjDB_mysql::Columns
	attr_reader :db, :driver
	
	def initialize(args)
		@args = args
		@db = @args[:db]
		@driver = @args[:driver]
	end
	
	def data_sql(name, data)
		Knj::ArrayExt.hash_sym(data)
		
		raise "No type given." if !data[:type]
		
		if data[:type] == "varchar" and !data[:maxlength]
			data[:maxlength] = 255
		end
		
		sql = "`#{name}` #{data[:type]}"
		
		if data[:maxlength]
			sql += "(#{data[:maxlength]})"
		end
		
		if data[:primarykey]
			sql += " PRIMARY KEY"
		end
		
		if data[:autoincr]
			sql += " AUTO_INCREMENT"
		end
		
		if !data[:null]
			sql += " NOT NULL"
		end
		
		if data[:default]
			sql += " DEFAULT '#{@db.sql(data[:default])}'"
		end
		
		return sql
	end
end

class KnjDB_mysql::Columns::Column
	def initialize(args)
		@db = args[:db]
		@driver = args[:driver]
		@cols = args[:cols]
	end
end