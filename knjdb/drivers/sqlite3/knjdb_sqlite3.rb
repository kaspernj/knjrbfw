class KnjDB_sqlite3
	attr_reader :knjdb, :conn, :escape_table, :escape_col, :escape_val, :esc_table, :esc_col, :symbolize
	attr_accessor :tables, :cols, :indexes
	
	def initialize(knjdb_ob)
		@escape_table = "`"
		@escape_col = "`"
		@escape_val = "'"
		@esc_table = "`"
		@esc_col = "`"
		
		@knjdb = knjdb_ob
		@path = @knjdb.opts[:path] if @knjdb.opts[:path]
		@path = @knjdb.opts["path"] if @knjdb.opts["path"]
		@symbolize = true if !@knjdb.opts.has_key?(:return_keys) or @knjdb.opts[:return_keys] == "symbols"
		
		raise "No path was given." if !@path
		
		@conn = SQLite3::Database.open(@path)
		@conn.results_as_hash = true
		@conn.type_translation = false
	end
	
	def query(string)
		return KnjDB_sqlite3_result.new(self, @conn.execute(string))
	end
	
	def escape(string)
    	return string.to_s.gsub("'", "\\'")
	end
	
	def esc_col(string)
		string = string.to_s
		raise "Invalid column-string: #{string}" if string.index(@escape_col) != nil
		return string
	end
	
	alias :esc_table :esc_col
	alias :esc :escape
	
	def lastID
		return @conn.last_insert_row_id
	end
end

class KnjDB_sqlite3_result
	def initialize(driver, result_array)
		@driver = driver
		@result_array = result_array
		@index = 0
	end
	
	def fetch
		tha_index = @index
		@index += 1
		
		tha_return = @result_array[tha_index]
		return false if !tha_return
		
		if tha_return.class.to_s == "SQLite3::ResultSet::HashWithTypes"
			tha_return = Hash.new.replace(tha_return)
		end
		
		if tha_return.is_a?(Hash)
			tha_return.each do |pair|
				if Knj::Php::is_numeric(pair[0])
					tha_return.delete(pair[0])
				end
			end
		end
		
		Knj::ArrayExt.hash_sym(tha_return) if @driver.symbolize
		
		return tha_return
	end
end