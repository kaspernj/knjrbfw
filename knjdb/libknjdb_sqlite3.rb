class KnjDB_sqlite3
	def escape_table
		return "`"
	end
	
	def escape_col
		return "`"
	end
	
	def escape_val
		return "'"
	end
	
	def initialize(knjdb_ob)
		@knjdb = knjdb_ob
		@conn = SQLite3::Database.open(@knjdb.opts["path"])
		@conn.results_as_hash = true
		@conn.type_translation = false
	end
	
	def query(string)
		return KnjDB_sqlite3_result.new(@conn.execute(string))
	end
	
	def escape(string)
		if (!string)
			return ""
		end
		
    	string = string.gsub("'", "\\'")
		return string
	end
	
	def lastID
		return @conn.last_insert_row_id
	end
end

class KnjDB_sqlite3_result
	def initialize(result_array)
		@result_array = result_array
		@index = 0
	end
	
	def fetch
		tha_index = @index
		@index += 1
		
		tha_return = @result_array[tha_index]
		
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
		
		return tha_return
	end
end