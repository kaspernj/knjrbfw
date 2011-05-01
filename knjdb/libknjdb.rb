class Knj::Db
	attr_reader :opts, :conn
	
	def initialize(opts)
		@conns = {}
		self.setOpts(opts) if opts != nil
	end
	
	def col_table
		return "`"
	end
	
	def args
		return @opts
	end
	
	def setOpts(arr_opts)
		@opts = {}
		
		arr_opts.each do |key, val|
			@opts[key.to_sym] = val
			
			if key.to_sym == :threadsafe and val
				@threadsafe = val
			end
		end
		
		if @opts[:type] == "sqlite3" and RUBY_PLATFORM == "java"
			@opts[:type] = "java_sqlite3"
		elsif @opts[:type] == "mysql" and RUBY_PLATFORM == "java"
			@opts[:subtype] = "java"
		elsif @opts[:type] == "sqlite3" and RUBY_PLATFORM.index("mswin32") != nil
			@opts[:type] = "sqlite3_ironruby"
		end
		
		self.connect
	end
	
	def connect
		@conn = self.spawn[:conn]
	end
	
	def spawn
		@spawn_working = true
		
		begin
			raise "No type given." if !@opts[:type]
			
			fpaths = [
				"drivers/#{@opts[:type]}/knjdb_#{@opts[:type]}.rb",
				"libknjdb_" + @opts[:type] + ".rb"
			]
			fpaths.each do |fpath|
				rpath = "#{File.dirname(__FILE__)}/#{fpath}"
				
				if File.exists?(rpath)
					require rpath
					break
				end
			end
			
			conn = Kernel.const_get("KnjDB_" + @opts[:type]).new(self)
			
			conn = {
				:conn => conn,
				:running => false
			}
			newconns = @conns.clone
			newconns[newconns.length] = conn
			@conns = newconns
		ensure
			@spawn_working = false
		end
		
		return conn
	end
	
	def close
		@conns.clone.each do |key, conn|
			conn[:conn].close
		end
		@conns = {}
	end
	
	def clone_conn
		return Knj::Db.new(@opts)
	end
	
	def copy_to(db)
		data["tables"].each do |table|
			db.tables.create(table["name"], table)
		end
	end
	
	def data
		tables_ret = []
		tables.list.each do |name, table|
			tables_ret << table.data
		end
		
		return {
			"tables" => tables_ret
		}
	end
	
	def insert(tablename, arr_insert)
		sql = "INSERT INTO #{@conn.escape_table}#{tablename.to_s}#{@conn.escape_table} ("
		
		first = true
		arr_insert.each do |key, value|
			if first
				first = false
			else
				sql += ", "
			end
			
			sql += "#{@conn.escape_col}#{key.to_s}#{@conn.escape_col}"
		end
		
		sql += ") VALUES ("
		
		first = true
		arr_insert.each do |key, value|
			if first
				first = false
			else
				sql += ", "
			end
			
			sql += "#{@conn.escape_val}#{@conn.escape(value.to_s)}#{@conn.escape_val}"
		end
		
		sql += ")"
		
		self.query(sql)
	end
	
	def insert_multi(tablename, arr_hashes)
		if @conn.respond_to?(:insert_multi)
			@conn.insert_multi(tablename, arr_hashes)
		else
			arr_hashes.each do |hash|
				self.insert(tablename, hash)
			end
		end
	end
	
	def update(tablename, arr_update, arr_terms = {})
		sql = "UPDATE #{@conn.escape_col}#{tablename.to_s}#{@conn.escape_col} SET "
		
		first = true
		arr_update.each do |key, value|
			if first
				first = false
			else
				sql += ", "
			end
			
			sql += "#{@conn.escape_col}#{key.to_s}#{@conn.escape_col} = "
			sql += "#{@conn.escape_val}#{@conn.escape(value.to_s)}#{@conn.escape_val}"
		end
		
		if arr_terms and arr_terms.length > 0
			sql += " WHERE #{self.makeWhere(arr_terms)}"
		end
		
		self.query(sql)
	end
	
	def select(tablename, arr_terms = nil, args = nil)
		sql = "SELECT * FROM #{@conn.escape_table}#{tablename.to_s}#{@conn.escape_table}"
		
		if arr_terms != nil
			sql += " WHERE #{self.makeWhere(arr_terms)}"
		end
		
		if args != nil
			if args["orderby"]
				sql += " ORDER BY "
				sql += args["orderby"]
			end
			
			if args["limit"]
				sql += " LIMIT " + args["limit"].to_s
			end
		end
		
		return self.query(sql)
	end
	
	def selectsingle(tablename, arr_terms = nil, args = {})
		args["limit"] = 1
		return self.select(tablename, arr_terms, args).fetch
	end
	
	def single(tablename, arr_terms = nil, args = {})
		args["limit"] = 1
		return self.select(tablename, arr_terms, args).fetch
	end
	
	def delete(tablename, arr_terms)
		sql = "DELETE FROM #{@conn.escape_table}#{tablename.to_s}#{@conn.escape_table}"
		
		if arr_terms != nil
			sql += " WHERE #{self.makeWhere(arr_terms)}"
		end
		
		self.query(sql)
	end
	
	def makeWhere(arr_terms)
		sql = ""
		
		first = true
		arr_terms.each do |key, value|
			if first
				first = false
			else
				sql += " AND "
			end
			
			sql += "#{@conn.escape_col}#{key.to_s}#{@conn.escape_col} = #{@conn.escape_val}#{@conn.escape(value)}#{@conn.escape_val}"
		end
		
		return sql
	end
	
	def query(string)
		return @conn.query(string) if !@threadsafe
		
		retconn = nil
		@conns.clone.each do |key, conn|
			next if conn[:running]
			retconn = conn
			break
		end
		
		if retconn
			retconn[:running] = true
			ret = retconn[:conn].query(string)
			retconn[:running] = false
			return ret
		end
		
		#all connections are taken - spawn new and run loop again.
		conn = self.spawn
		conn[:running] = true
		ret = conn[:conn].query(string)
		conn[:running] = false
		return ret
	end
	
	def lastID
		return @conn.lastID
	end
	
	alias :last_id :lastID
	
	def escape(string)
		return @conn.escape(string)
	end
	
	alias :esc :escape
	
	def esc_col(str)
		return @conn.esc_col(str)
	end
	
	def esc_table(str)
		return @conn.esc_table(str)
	end
	
	def tables
		if !@conn.tables
			require "#{File.dirname(__FILE__)}/drivers/#{@opts[:type]}/knjdb_#{@opts[:type]}_tables"
			@conn.tables = Kernel.const_get("KnjDB_#{@opts[:type]}".to_sym).const_get(:Tables).new(
				:driver => @conn,
				:db => self
			)
		end
		
		return @conn.tables
	end
	
	def cols
		if !@cols
			require "#{File.dirname(__FILE__)}/drivers/#{@opts[:type]}/knjdb_#{@opts[:type]}_columns"
			@cols = Kernel.const_get("KnjDB_#{@opts[:type]}".to_sym).const_get(:Columns).new(
				:driver => @conn,
				:db => self
			)
		end
		
		return @cols
	end
	
	def indexes
		if !@indexes
			require "#{File.dirname(__FILE__)}/drivers/#{@opts[:type]}/knjdb_#{@opts[:type]}_indexes"
			@indexes = Kernel.const_get("KnjDB_#{@opts[:type]}".to_sym).const_get(:Indexes).new(
				:driver => @conn,
				:db => self
			)
		end
		
		return @indexes
	end
	
	def method_missing(method_name, *args)
		if @conn.respond_to?(method_name.to_sym)
			return @conn.send(method_name, *args)
		end
		
		raise "Method not found: #{method_name}"
	end
end