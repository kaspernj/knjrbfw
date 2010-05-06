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
		
		require "mysql"
		@conn = Mysql.real_connect(knjdb_ob.opts["host"], knjdb_ob.opts["user"], knjdb_ob.opts["pass"], knjdb_ob.opts["db"])
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
	end
	
	def fetch
		return @result.fetch_hash
	end
end