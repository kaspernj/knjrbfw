class KnjDB_mysql2
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
		args = {
			:host => @knjdb.opts[:host],
			:username => @knjdb.opts[:user],
			:password => @knjdb.opts[:pass],
			:database => @knjdb.opts[:db],
			:port => @port,
			:symbolize_keys => true
		}
		
		require "rubygems"
		require "mysql2"
		@conn = Mysql2::Client.new(args)
	end
	
	def query(string)
		return KnjDB_mysql2_result.new(@conn.query(string))
	end
	
	def escape(string)
		return @conn.escape(string.to_s)
	end
	
	def esc_col(string)
		string = string.to_s
		raise "Invalid column-string: #{string}" if string.index(@escape_col) != nil
		return string
	end
	
	alias :esc_table :esc_col
	alias :esc :escape
	
	def lastID
		return self.query("SELECT LAST_INSERT_ID() AS id").fetch[:id]
	end
	
	def destroy
		@conn = nil
		@knjdb = nil
	end
end

class KnjDB_mysql2_result
	def initialize(result)
		@result = result.to_a
		@count = 0
	end
	
	def fetch
		ret = @result[@count]
		return false if !ret
		
		realret = {}
		ret.each do |key, val|
			realret[key.to_sym] = val
		end
		
		@count += 1
		return realret
	end
end