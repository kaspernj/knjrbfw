class KnjDB_mysql
	attr_reader :knjdb, :conn, :escape_table, :escape_col, :escape_val, :esc_table
	attr_accessor :tables, :cols, :indexes
	
	def initialize(knjdb_ob)
		@knjdb = knjdb_ob
		@encoding = @knjdb.opts[:encoding]
		@escape_table = "`"
		@escape_col = "`"
		@escape_val = "'"
		@esc_table = "`"
		@esc_col = "`"
		@mutex = Mutex.new
		
		if @knjdb.opts.key?(:port)
			@port = @knjdb.opts[:port].to_i
		else
			@port = 3306
		end
		
		@subtype = @knjdb.opts[:subtype]
		reconnect
	end
	
	def reconnect
		if !@subtype or @subtype == "mysql"
			@conn = Mysql.real_connect(@knjdb.opts[:host], @knjdb.opts[:user], @knjdb.opts[:pass], @knjdb.opts[:db], @port)
		elsif @subtype == "mysql2"
			require "rubygems"
			require "mysql2"
			
			args = {
        :host => @knjdb.opts[:host],
        :username => @knjdb.opts[:user],
        :password => @knjdb.opts[:pass],
        :database => @knjdb.opts[:db],
        :port => @port,
        :symbolize_keys => true
			}
			
			@query_args = @knjdb.opts[:query_args]
			@query_args = {} if !@query_args
			
			pos_args = [:as, :async, :cast_booleans, :database_timezone, :application_timezone, :cache_rows, :connect_flags, :cast]
			pos_args.each do |key|
        args[key] = @knjdb.opts[key] if @knjdb.opts.key?(key)
			end
			
			@conn = Mysql2::Client.new(args)
		elsif @subtype == "java"
			if !@jdbc_loaded
				require "java"
				
				if File.exists?("/usr/share/java/mysql-connector-java.jar")
					require "/usr/share/java/mysql-connector-java.jar"
				else
					require File.dirname(__FILE__) + "/mysql-connector-java-5.1.13-bin.jar"
				end
				
				import "com.mysql.jdbc.Driver"
				@jdbc_loaded = true
			end
			
			@conn = java.sql::DriverManager.getConnection("jdbc:mysql://#{@knjdb.opts[:host]}:#{@port}/#{@knjdb.opts[:db]}?user=#{@knjdb.opts[:user]}&password=#{@knjdb.opts[:pass]}&populateInsertRowWithDefaultValues=true&zeroDateTimeBehavior=round")
			query("SET SQL_MODE = ''")
		else
			raise "Unknown subtype: #{@subtype}"
		end
		
		query_conn(@conn, "SET NAMES '#{esc(@encoding)}'") if @encoding
	end
	
	def query_conn(conn, str)
		if @subtype == "java"
			stmt = conn.createStatement
			
			if str.match(/insert\s+into\s+/i) or str.match(/update\s+/i) or str.match(/^\s*delete\s+/i) or str.match(/^\s*create\s*/i)
				return stmt.execute(str)
			else
				return stmt.executeQuery(str)
			end
		elsif conn.respond_to?(:query)
			return conn.query(str)
		else
			raise "Could not figure out the way to execute the query on #{conn.class.name}."
		end
	end
	
	def query(string)
		string = string.to_s
		string = string.force_encoding("UTF-8") if @encoding == "utf8" and string.respond_to?(:force_encoding)
		
		@mutex.synchronize do
			if !@subtype or @subtype == "mysql"
				begin
					return KnjDB_mysql_result.new(self, @conn.query(string))
				rescue Mysql::Error => e
					if e.message == "MySQL server has gone away"
						reconnect
						retry
					else
						raise e
					end
				end
			elsif @subtype == "mysql2"
				begin
					return KnjDB_mysql2_result.new(@conn.query(string, @query_args))
				rescue Mysql2::Error => e
					if e.message == "MySQL server has gone away" or e.message == "closed MySQL connection"
						reconnect
						retry
					elsif e.message == "This connection is still waiting for a result, try again once you have the result"
						sleep 0.1
						retry
					else
						print string
						raise e
					end
				end
			elsif @subtype == "java"
				begin
					return KnjDB_java_mysql_result.new(@knjdb, query_conn(@conn, string))
				rescue => e
					if e.to_s.index("No operations allowed after connection closed") != nil
						reconnect
						retry
					end
					
					raise e
				end
			else
				raise "Unknown subtype: '#{@subtype}'."
			end
		end
	end
	
	def escape(string)
		if !@subtype or @subtype == "mysql"
			return @conn.escape_string(string.to_s)
		elsif @subtype == "mysql2"
			return @conn.escape(string.to_s)
		elsif @subtype == "java"
			#This is copied from the Ruby/MySQL framework at: http://www.tmtm.org/en/ruby/mysql/
			return string.to_s.gsub(/([\0\n\r\032\'\"\\])/) do
				case $1
					when "\0" then "\\0"
					when "\n" then "\\n"
					when "\r" then "\\r"
					when "\032" then "\\Z"
					else "\\" + $1
				end
			end
		else
			raise "Unknown subtype: '#{@subtype}'."
		end
	end
	
	def esc_col(string)
		string = string.to_s
		raise "Invalid column-string: #{string}" if string.index(@escape_col) != nil
		return string
	end
	
	alias :esc_table :esc_col
	alias :esc :escape
	
	def lastID
		if !@subtype or @subtype == "mysql"
			@mutex.synchronize do
				return @conn.insert_id
			end
		elsif @subtype == "mysql2"
			@mutex.synchronize do
				return @conn.last_id
			end
		else
			data = self.query("SELECT LAST_INSERT_ID() AS id").fetch
			return data[:id] if data.key?(:id)
			raise "Could not figure out last inserted ID."
		end
	end
	
	def close
		@mutex.synchronize do
			@conn.close
		end
	end
	
	def destroy
		@conn = nil
		@knjdb = nil
		@mutex = nil
		@subtype = nil
		@encoding = nil
		@query_args = nil
		@port = nil
	end
	
	def insert_multi(tablename, arr_hashes)
		sql = "INSERT INTO `#{esc_table(tablename)}` ("
		
		first = true
		arr_hashes[0].keys.each do |col_name|
			sql += "," if !first
			first = false if first
			sql += "`#{esc_col(col_name)}`"
		end
		
		sql += ") VALUES ("
		
		first = true
		arr_hashes.each do |hash|
			sql += "),(" if !first
			first = false if first
			
			first_key = true
			hash.each do |key, val|
				sql += "," if !first_key
				first_key = false if first_key
				sql += "'#{esc(val)}'"
			end
		end
		
		sql += ")"
		
		query(sql)
	end
end

class KnjDB_mysql_result
	def initialize(driver, result)
		@driver = driver
		@result = result
		@mutex = Mutex.new
		
		if @result
			@keys = []
			keys = @result.fetch_fields
			keys.each do |key|
				@keys << key.name.to_sym
			end
		end
	end
	
	def fetch
		return fetch_hash_symbols if @driver.knjdb.opts[:return_keys] == "symbols"
		return fetch_hash_strings
	end
	
	def fetch_hash_strings
		@mutex.synchronize do
			return @result.fetch_hash
		end
	end
	
	def fetch_hash_symbols
		@mutex.synchronize do
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
end

class KnjDB_mysql2_result
	def initialize(result)
		@result = result.to_a
		@count = 0
		@mutex = Mutex.new
	end
	
	def fetch
		@mutex.synchronize do
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
end

class KnjDB_java_mysql_result
	def initialize(knjdb, result)
		@knjdb = knjdb
		@result = result
		@mutex = Mutex.new
	end
	
	def read_meta
		@result.before_first
		meta = @result.meta_data
		
		@keys = []
		0.upto(meta.column_count - 1) do |count|
			@keys << meta.column_name(count + 1).to_sym
		end
	end
	
	def fetch
		@mutex.synchronize do
			read_meta if !@keys
			status = @result.next
			return false if !status
			
			ret = {}
			0.upto(@keys.length - 1) do |count|
				ret[@keys[count].to_sym] = @result.string(count + 1)
			end
			
			return ret
		end
	end
end