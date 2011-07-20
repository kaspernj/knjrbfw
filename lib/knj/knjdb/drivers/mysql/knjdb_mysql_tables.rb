class KnjDB_mysql::Tables
	attr_reader :db, :driver
	attr_accessor :list
	
	def initialize(args)
		@args = args
		@db = @args[:db]
		@driver = @args[:driver]
		@subtype = @db.opts[:subtype]
		@list_mutex = Mutex.new
	end
	
	def [](table_name)
		list = self.list
		return list[table_name.to_s] if list[table_name.to_s]
		raise Knj::Errors::NotFound.new("Table was not found: #{table_name}.")
	end
	
	def list
		if !@list
      @list_mutex.synchronize do
        list = {}
        @db.q("SHOW TABLE STATUS") do |d_tables|
          if @subtype == "java"
            d_tables = {
              :Name => d_tables[:TABLE_NAME],
              :Engine => d_tables[:ENGINE],
              :Version => d_tables[:VERSION],
              :Row_format => d_tables[:ROW_FORMAT],
              :Rows => d_tables[:TABLE_ROWS],
              :Avg_row_length => d_tables[:AVG_ROW_LENGTH],
              :Data_length => d_tables[:DATA_LENGTH],
              :Max_data_length => d_tables[:MAX_DATA_LENGTH],
              :Index_length => d_tables[:INDEX_LENGTH],
              :Data_free => d_tables[:DATA_FREE],
              :Auto_increment => d_tables[:AUTO_INCREMENT],
              :Create_time => d_tables[:CREATE_TIME],
              :Update_time => d_tables[:UPDATE_TIME],
              :Check_time => d_tables[:CHECK_TIME],
              :Collation => d_tables[:TABLE_COLLATION],
              :Checksum => d_tables[:CHECKSUM],
              :Create_options => d_tables[:CREATE_OPTIONS],
              :Comment => d_tables[:TABLE_COMMENT]
            }
          end
          
          list[d_tables[:Name]] = KnjDB_mysql::Tables::Table.new(
            :db => @db,
            :driver => @driver,
            :data => d_tables,
            :tables => self
          )
        end
        
        @list = list
      end
		end
		
		return @list
	end
	
	def create(name, data)
		raise "No columns was given for '#{name}'." if !data["columns"] or data["columns"].empty?
		
		sql = "CREATE TABLE `#{name}` ("
		
		first = true
		data["columns"].each do |col_data|
			sql += ", " if !first
			first = false if first
			col_data.delete("after") if col_data["after"]
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
	attr_accessor :list
	
	def initialize(args)
		@args = args
		@db = args[:db]
		@driver = args[:driver]
		@data = args[:data]
		@subtype = @db.opts[:subtype]
		
		raise "Could not figure out name." if !@data[:Name]
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
				if @subtype == "java"
					d_cols = {
						:Field => d_cols[:COLUMN_NAME],
						:Type => d_cols[:COLUMN_TYPE],
						:Collation => d_cols[:COLLATION_NAME],
						:Null => d_cols[:IS_NULLABLE],
						:Key => d_cols[:COLUMN_KEY],
						:Default => d_cols[:COLUMN_DEFAULT],
						:Extra => d_cols[:EXTRA],
						:Privileges => d_cols[:PRIVILEGES],
						:Comment => d_cols[:COLUMN_COMMENT]
					}
				end
				
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
			
			q_indexes = @db.query("SHOW INDEX FROM `#{self.name}`")
			while d_indexes = q_indexes.fetch
        if @subtype == "java"
          d_indexes = {
            :Table => d_indexes[:TABLE_NAME],
            :Non_unique => d_indexes[:NON_UNIQUE],
            :Key_name => d_indexes[:INDEX_NAME],
            :Seq_in_index => d_indexes[:SEQ_IN_INDEX],
            :Column_name => d_indexes[:COLUMN_NAME],
            :Collation => d_indexes[:COLLATION],
            :Cardinality => d_indexes[:CARDINALITY],
            :Sub_part => d_indexes[:SUB_PART],
            :Packed => d_indexes[:PACKED],
            :Null => d_indexes[:NULLABLE],
            :Index_type => d_indexes[:INDEX_TYPE],
            :Comment => d_indexes[:COMMENT]
          }
        end
        
				next if d_indexes[:Key_name] == "PRIMARY"
				
				if !@indexes_list[d_indexes[:Key_name]]
					@indexes_list[d_indexes[:Key_name]] = KnjDB_mysql::Indexes::Index.new(
						:table => self,
						:db => @db,
						:driver => @driver,
						:data => d_indexes
					)
				end
				
				@indexes_list[d_indexes[:Key_name]].columns << d_indexes[:Column_name]
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
			
			print sql + "\n"
			@db.query(sql)
		end
	end
	
	def rename(newname)
		oldname = self.name
		@db.query("ALTER TABLE `#{oldname}` RENAME TO `#{newname}`")
		@args[:tables].list[newname] = self
		@args[:tables].list.delete(oldname)
		@data[:Name] = newname
	end
	
	def data
		ret = {
			"name" => name,
			"columns" => [],
			"indexes" => []
		}
		
		columns.each do |name, column|
			ret["columns"] << column.data
		end
		
		indexes.each do |name, index|
			ret["indexes"] << index.data if name != "PRIMARY"
		end
		
		return ret
	end
end