class KnjDB_mysql
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
		
		if knjdb_ob.opts.has_key?("port")
			port = knjdb_ob.opts["port"].to_i
		else
			port = 3306
		end
		
		@conn = Mysql.real_connect(knjdb_ob.opts["host"], knjdb_ob.opts["user"], knjdb_ob.opts["pass"], knjdb_ob.opts["db"], port)
	end
	
	def query(string)
		return KnjDB_mysql_result.new(@conn.query(string))
	end
	
	def escape(string)
		return @conn.escape_string(string.to_s)
	end
	
	def lastID
		return @conn.insert_id
	end
	
	def destroy
		@conn = nil
		@knjdb = nil
	end
end

class KnjDB_mysql_result
	def initialize(result)
		@result = result
		if @result
			@keys = []
			keys = @result.fetch_fields
			keys.each do |key|
				@keys << key.name.to_sym
			end
		end
	end
	
	def fetch
		if $db and $db.opts["return_keys"] == "symbols"
			return self.fetch_hash_symbols
		end
		
		return self.fetch_hash_strings
	end
	
	def fetch_hash_strings
		return @result.fetch_hash
	end
	
	def fetch_hash_symbols
		fetched = @result.fetch_row
		return false if !fetched
		
		ret = {}
		count = 0
		@keys.each do |key|
			ret[key] = fetched[count]
			count += 1
		end
		
		return ret
	end
end