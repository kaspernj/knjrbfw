require "java"

class KnjDB_java_mysql
	attr_reader :knjdb, :conn, :escape_table, :escape_col, :escape_val
	
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
		@escape_table = "`"
		@escape_col = "`"
		@escape_val = "'"
		@knjdb = knjdb_ob
		
		if knjdb_ob.opts.has_key?(:port)
			@port = knjdb_ob.opts[:port].to_i
		else
			@port = 3306
		end
		
		if File.exists?("/usr/share/java/mysql-connector-java.jar")
			require "/usr/share/java/mysql-connector-java.jar"
		else
			require File.dirname(__FILE__) + "/mysql-connector-java-5.1.13-bin.jar"
		end
		
		import "com.mysql.jdbc.Driver"
		self.reconnect
		self.query("SET SQL_MODE = ''")
	end
	
	def reconnect
		@conn = java.sql::DriverManager.getConnection("jdbc:mysql://#{@knjdb.opts[:host]}:#{@port}/#{@knjdb.opts[:db]}?user=#{@knjdb.opts[:user]}&password=#{@knjdb.opts[:pass]}&populateInsertRowWithDefaultValues=true&zeroDateTimeBehavior=round")
	end
	
	def query(sqlstr)
		stmt = @conn.createStatement
		
		if sqlstr.match(/insert\s+into\s+/i) or sqlstr.match(/update\s+/i)
			rs = stmt.execute(sqlstr)
		else
			rs = stmt.executeQuery(sqlstr)
		end
		
		return KnjDB_java_mysql_result.new(@knjdb, rs)
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
		data = self.query("SELECT LAST_INSERT_ID() AS id").fetch
		return data[:id] if data.has_key?(:id)
		return data["id"] if data.has_key?("id")
		raise "Could not get the last ID from database."
	end
	
	def destroy
		@conn = nil
		@knjdb = nil
		@knjdb.opts = nil
		@port = nil
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
		if @knjdb.opts[:return_keys].to_s == "symbols"
			0.upto(@keys.length - 1) do |count|
				ret[@keys[count].to_sym] = @result.string(count + 1)
			end
		else
			0.upto(@keys.length - 1) do |count|
				ret[@keys[count].to_s] = @result.string(count + 1)
			end
		end
		
		return ret
	end
end