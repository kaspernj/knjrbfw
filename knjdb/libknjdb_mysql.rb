class KnjDB_mysql
	attr_reader :knjdb, :conn, :escape_table, :escape_col, :escape_val
	
	def initialize(knjdb_ob)
		@knjdb = knjdb_ob
		@escape_table = "`"
		@escape_col = "`"
		@escape_val = "'"
		
		if @knjdb.opts.has_key?(:port)
			@port = @knjdb.opts[:port].to_i
		else
			@port = 3306
		end
		
		self.reconnect
	end
	
	def reconnect
		@conn = Mysql.real_connect(@knjdb.opts[:host], @knjdb.opts[:user], @knjdb.opts[:pass], @knjdb.opts[:db], @port)
	end
	
	def query(string)
		begin
			return KnjDB_mysql_result.new(@conn.query(string))
		rescue Mysql::Error => e
			if e.message == "MySQL server has gone away"
				print "Reconnect!\n"
				self.reconnect
				return KnjDB_mysql_result.new(@conn.query(string))
			else
				raise e
			end
		end
	end
	
	def escape(string)
		return @conn.escape_string(string.to_s)
	end
	
	def esc_col(string)
		string = string.to_s
		raise "Invalid column-string: #{string}" if string.index(@escape_col) != nil
		return string
	end
	
	alias :esc_table :esc_col
	alias :esc :escape
	
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
		return self.fetch_hash_symbols if $db and $db.opts[:return_keys] == "symbols"
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