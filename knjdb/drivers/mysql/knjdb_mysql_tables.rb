class KnjDB_mysql::Tables
	attr_reader :db, :driver
	
	def initialize(args)
		@args = args
		@db = @args[:db]
		@driver = @args[:driver]
	end
	
	def [](table_name)
		list = self.list
		return list[table_name.to_s] if list[table_name.to_s]
		raise Knj::Errors::NotFound.new("Table was not found: #{table_name}.")
	end
	
	def list
		if !@list
			@list = {}
			q_tables = @db.query("SHOW TABLE STATUS")
			while d_tables = q_tables.fetch
				@list[d_tables[:Name]] = KnjDB_mysql::Tables::Table.new(
					:db => @db,
					:driver => @driver,
					:data => d_tables
				)
			end
		end
		
		return @list
	end
	
	def create(name, data)
		Knj::ArrayExt.hash_sym(data)
		sql = "CREATE TABLE `#{name}` ("
		
		first = true
		data["columns"].each do |col_name, col_data|
			if first
				first = false
			else
				sql += ", "
			end
			
			sql += @db.cols.data_sql(col_name, col_data)
		end
		
		sql += ")"
		@db.query(sql)
	end
end

class KnjDB_mysql::Tables::Table
	def initialize(args)
		@db = args[:db]
		@driver = args[:driver]
		@data = args[:data]
	end
	
	def name
		return @data[:Name]
	end
	
	def drop
		sql = "DROP TABLE `#{self.name}`"
		@db.query(sql)
	end
	
	def optimize
		raise "stub!"
	end
	
	def column(name)
		list = self.columns
		return list[name] if list[name]
		raise Knj::Errors::NotFound.new("Column not found: #{name}.")
	end
	
	def columns
		if !@list
			@db.cols
			@list = {}
			sql = "SHOW FULL COLUMNS FROM `#{self.name}`"
			
			q_cols = @db.query(sql)
			while d_cols = q_cols.fetch
				@list[d_cols[:Field]] = KnjDB_mysql::Columns::Column.new(
					:table => self,
					:db => @db,
					:driver => @driver,
					:data => d_cols
				)
			end
		end
		
		return @list
	end
	
	def create_columns(col_arr)
		col_arr.each do |col_data|
			sql = "ALTER TABLE `#{self.name}` ADD COLUMN #{@db.cols.data_sql(col_data[:name], col_data[:data])};"
			@db.query(sql)
		end
	end
end