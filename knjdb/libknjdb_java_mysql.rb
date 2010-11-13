require "java"

class KnjDB_java_mysql
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
		@opts = knjdb_ob.opts
		
		if knjdb_ob.opts.has_key?(:port)
			@port = knjdb_ob.opts[:port].to_i
		else
			@port = 3306
		end
		
		require File.dirname(__FILE__) + "/mysql-connector-java-5.1.13-bin.jar"
		import "com.mysql.jdbc.Driver"
		self.reconnect
		self.query("SET SQL_MODE = ''")
	end
	
	def reconnect
		@conn = java.sql::DriverManager.getConnection("jdbc:mysql://#{@opts[:host]}:#{@port}/#{@opts[:db]}?user=#{@opts[:user]}&password=#{@opts[:pass]}&populateInsertRowWithDefaultValues=true&zeroDateTimeBehavior=round")
	end
	
	def query(sqlstr)
		stmt = @conn.createStatement
		
		if sqlstr.match(/insert\s+into\s+/i) or sqlstr.match(/update\s+/i)
			rs = stmt.execute(sqlstr)
		else
			rs = stmt.executeQuery(sqlstr)
		end
		
		return KnjDB_java_mysql_result.new(rs)
	end
	
	def escape(string)
		return string.gsub("'", "\\'")
	end
	
	def lastID
		data = self.query("SELECT LAST_INSERT_ID() AS id").fetch
		return data[:id]
	end
	
	def destroy
		@conn = nil
		@knjdb = nil
		@opts = nil
		@port = nil
	end
end

class KnjDB_java_mysql_result
	def initialize(result)
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
		if $db and $db.opts[:return_keys] == "symbols"
			0.upto(@keys.length - 1) do |count|
				ret[@keys[count]] = @result.string(count + 1)
			end
		else
			0.upto(@keys.length - 1) do |count|
				ret[@keys[count].to_s] = @result.string(count + 1)
			end
		end
		
		return ret
	end
end