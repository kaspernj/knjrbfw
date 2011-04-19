class KnjDB_mysql
	attr_reader :knjdb, :conn, :escape_table, :escape_col, :escape_val, :esc_table, :esc_col
	attr_accessor :tables, :cols, :indexes
	
	def initialize(knjdb_ob)
		@knjdb = knjdb_ob
		@escape_table = "`"
		@escape_col = "`"
		@escape_val = "'"
		@esc_table = "`"
		@esc_col = "`"
		
		if @knjdb.opts.has_key?(:port)
			@port = @knjdb.opts[:port].to_i
		else
			@port = 3306
		end
		
		@subtype = @knjdb.opts[:subtype]
		
		self.reconnect
	end
	
	def reconnect
		if !@subtype or @subtype == "mysql"
			@conn = Mysql.real_connect(@knjdb.opts[:host], @knjdb.opts[:user], @knjdb.opts[:pass], @knjdb.opts[:db], @port)
		elsif @subtype == "mysql2"
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
			self.query("SET SQL_MODE = ''")
		else
			raise "Unknown subtype: #{@subtype}"
		end
		
		if @knjdb.opts[:encoding]
			@conn.query("SET NAMES '#{self.esc(@knjdb.opts[:encoding])}'")
		end
	end
	
	def query(string)
		if !@subtype or @subtype == "mysql"
			begin
				return KnjDB_mysql_result.new(self, @conn.query(string))
			rescue Mysql::Error => e
				if e.message == "MySQL server has gone away"
					self.reconnect
					return KnjDB_mysql_result.new(@conn.query(string))
				else
					print "SQL: #{string}\n\n"
					
					puts e.message
					puts e.backtrace
					
					raise e
				end
			end
		elsif @subtype == "mysql2"
			begin
				return KnjDB_mysql2_result.new(@conn.query(string))
			rescue Mysql2::Error => e
				if e.message == "MySQL server has gone away"
					self.reconnect
					return KnjDB_mysql2_result.new(@conn.query(string))
				else
					raise e
				end
			end
		elsif @subtype == "java"
			stmt = @conn.createStatement
			
			if string.match(/insert\s+into\s+/i) or string.match(/update\s+/i)
				rs = stmt.execute(string)
			else
				rs = stmt.executeQuery(string)
			end
			
			return KnjDB_java_mysql_result.new(@knjdb, rs)
		end
	end
	
	def escape(string)
		if !@subtype or @subtype == "mysql"
			return @conn.escape_string(string.to_s)
		elsif @subtype == "mysql2"
			return @conn.escape(string.to_s)
		elsif @subtype == "java"
			return string.to_s.gsub("'", "\\'")
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
			return @conn.insert_id
		else
			data = self.query("SELECT LAST_INSERT_ID() AS id").fetch
			return data[:id] if data.has_key?(:id)
		end
	end
	
	def destroy
		@conn = nil
		@knjdb = nil
	end
end

class KnjDB_mysql_result
	def initialize(driver, result)
		@driver = driver
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
		return self.fetch_hash_symbols if @driver.knjdb.opts[:return_keys] == "symbols"
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

class KnjDB_java_mysql_result
	def initialize(knjdb, result)
		@knjdb = knjdb
		@result = result
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
		self.read_meta if !@keys
		status = @result.next
		return false if !status
		
		ret = {}
		0.upto(@keys.length - 1) do |count|
			ret[@keys[count].to_sym] = @result.string(count + 1)
		end
		
		return ret
	end
end