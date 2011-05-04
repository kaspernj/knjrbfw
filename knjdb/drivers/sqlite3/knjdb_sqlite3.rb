class KnjDB_sqlite3
	attr_reader :knjdb, :conn, :escape_table, :escape_col, :escape_val, :esc_table, :esc_col
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
		
		raise "No path was given." if !@path
		
		if @knjdb.opts[:subtype] == "rhodes"
			@conn = SQLite3::Database.new(@path, @path)
		else
			@conn = SQLite3::Database.open(@path)
			@conn.results_as_hash = true
			@conn.type_translation = false
		end
	end
	
	def query(string)
		if @knjdb.opts[:subtype] == "rhodes"
			res = @conn.execute(string, string)
		else
			res = @conn.execute(string)
		end
		
		return KnjDB_sqlite3_result.new(self, res)
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
		@result_array = result_array
		@index = 0
		@retkeys = driver.knjdb.opts[:return_keys]
	end
	
	def fetch
		tha_return = @result_array[@index]
		return false if !tha_return
		@index += 1
		
		ret = {}
		tha_return.each do |key, val|
			if Knj::Php::is_numeric(key)
				#do nothing.
			elsif @retkeys == "symbols" and !key.is_a?(Symbol)
				ret[key.to_sym] = val
			else
				ret[key] = val
			end
		end
		
		return ret
	end
end