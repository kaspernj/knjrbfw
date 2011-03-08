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
		sql = "CREATE TABLE `#{name}` ("
		
		first = true
		data["columns"].each do |col_data|
			if first
				first = false
			else
				sql += ", "
			end
			
			sql += @db.cols.data_sql(col_data)
		end
		
		sql += ")"
		@db.query(sql)
		@list = nil
		
		if data["indexes"]
			table_obj = self[name]
			table_obj.create_indexes(data["indexes"])
		end
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
	
	def indexes
		if !@indexes_list
			@db.indexes
			@indexes_list = {}
			sql = "SHOW INDEX FROM `#{self.name}`"
			
			q_indexes = @db.query(sql)
			while d_indexes = q_indexes.fetch
				@indexes_list[d_indexes[:Key_name]] = KnjDB_mysql::Indexes::Index.new(
					:table => self,
					:db => @db,
					:driver => @driver,
					:data => d_indexes
				)
			end
		end
		
		return @indexes_list
	end
	
	def index(name)
		list = self.indexes
		return list[name] if list[name]
		raise Knj::Errors::NotFound.new("Index not found: #{name}.")
	end
	
	def create_columns(col_arr)
		col_arr.each do |col_data|
			sql = "ALTER TABLE `#{self.name}` ADD COLUMN #{@db.cols.data_sql(col_data)};"
			@db.query(sql)
		end
	end
	
	def create_indexes(index_arr)
		index_arr.each do |index_data|
			raise "No name was given." if !index_data.has_key?("name") or index_data["name"].strip.length <= 0
			raise "No columns was given on index #{index_data["name"]}." if index_data["columns"].empty?
			
			sql = "CREATE INDEX #{@db.escape_col}#{@db.esc_col(index_data["name"])}#{@db.escape_col} ON #{@db.escape_table}#{@db.esc_table(self.name)}#{@db.escape_table} ("
			
			first = true
			index_data["columns"].each do |col_name|
				sql += ", " if !first
				first = false if first
				
				sql += "#{@db.escape_col}#{@db.esc_col(col_name)}#{@db.escape_col}"
			end
			
			sql += ")"
			
			@db.query(sql)
		end
	end
end