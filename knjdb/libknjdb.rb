class Knj::Db
	attr_reader :opts, :conn, :conns
	
	def initialize(opts)
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
		@conn = self.spawn
		
		if @opts[:threadsafe]
			@conns = Knj::Threadhandler.new
			
			@conns.on_spawn_new do
				spawn
			end
			
			@conns.on_inactive do |data|
				data[:obj].close
			end
			
			@conns.on_activate do |data|
				data[:obj].reconnect
			end
		end
	end
	
	def spawn
		raise "No type given." if !@opts[:type]
		
		fpaths = [
			"drivers/#{@opts[:type]}/knjdb_#{@opts[:type]}.rb",
			"libknjdb_" + @opts[:type] + ".rb"
		]
		fpaths.each do |fpath|
			rpath = "#{File.dirname(__FILE__)}/#{fpath}"
			
			if (!@opts.has_key?(:require) or @opts[:require]) and File.exists?(rpath)
				require rpath
				break
			end
		end
		
		return Kernel.const_get("KnjDB_" + @opts[:type]).new(self)
	end
	
	def close
		@conn.close if @conn
		
		if @conns
			@conns.objects.each do |data|
				data[:object].close
			end
		end
	end
	
	def clone_conn
		return Knj::Db.new(@opts)
	end
	
	def copy_to(db, args = {})
		data["tables"].each do |table|
			table_args = nil
			table_args = args["tables"][table["name"].to_s] if args and args["tables"] and args["tables"][table["name"].to_s]
			next if table_args and table_args["skip"]
			db.tables.create(table["name"], table)
			
			limit_from = 0
			limit_incr = 1000
			
			loop do
				ins_arr = []
				q_rows = self.select(table["name"], {}, {"limit_from" => limit_from, "limit_to" => limit_incr})
				while d_rows = q_rows.fetch
					col_args = nil
					
					if table_args and table_args["columns"]
						d_rows.each do |col_name, col_data|
							col_args = table_args["columns"][col_name.to_s] if table_args and table_args["columns"]
							d_rows[col_name] = "" if col_args and col_args["empty"]
						end
					end
					
					ins_arr << d_rows
				end
				
				break if ins_arr.empty?
				
				db.insert_multi(table["name"], ins_arr)
				limit_from += limit_incr
			end
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
	
	def insert(tablename, arr_insert, args = {})
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
		
		if args[:return_id]
			if @conns
				conn = @conns.get_and_lock
				
				begin
					conn.query(sql)
					return conn.lastID
				ensure
					@conns.free(conn)
				end
			else
				sleep 0.1 while @working
				@working = true
				
				begin
					@conn.query(sql)
					return @conn.lastID
				ensure
					@working = false
				end
			end
		else
			self.query(sql)
		end
	end
	
	def insert_multi(tablename, arr_hashes)
		if @conn.respond_to?(:insert_multi)
			return false if arr_hashes.empty?
			@conn.insert_multi(tablename, arr_hashes)
		else
			arr_hashes.each do |hash|
				self.insert(tablename, hash)
			end
		end
	end
	
	def update(tablename, arr_update, arr_terms = {})
		return false if arr_update.empty?
		
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
		
		if arr_terms != nil and !arr_terms.empty?
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
			
			if args["limit_from"] and args["limit_to"]
				raise "'limit_from' was not numeric: '#{args["limit_from"]}'." if !Knj::Php.is_numeric(args["limit_from"])
				raise "'limit_to' was not numeric: '#{args["limit_to"]}'." if !Knj::Php.is_numeric(args["limit_to"])
				
				sql += " LIMIT #{args["limit_from"]}, #{args["limit_to"]}"
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
		if !@working
			begin
				@working = true
				return @conn.query(string)
			ensure
				@working = false
			end
		end
		
		if !@conns
			sleep 0.1 while @working
			
			begin
				@working = true
				return @conn.query(string)
			ensure
				@working = false
			end
		else
			conn = @conns.get_and_lock
			
			begin
				return conn.query(string)
			ensure
				@conns.free(conn)
			end
		end
	end
	
	def q(str)
		ret = query(str)
		
		if block_given?
			while data = ret.fetch
				yield data
			end
		end
		
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
	
	def date_out(date_obj)
		return Knj::Datet.in(date_obj).dbstr
	end
	
	def date_in(date_obj)
		return Knj::Datet.in(date_obj)
	end
	
	def tables
		if !@conn.tables
			require "#{File.dirname(__FILE__)}/drivers/#{@opts[:type]}/knjdb_#{@opts[:type]}_tables" if (!@opts.has_key?(:require) or @opts[:require])
			@conn.tables = Kernel.const_get("KnjDB_#{@opts[:type]}".to_sym).const_get(:Tables).new(
				:driver => @conn,
				:db => self
			)
		end
		
		return @conn.tables
	end
	
	def cols
		if !@cols
			require "#{File.dirname(__FILE__)}/drivers/#{@opts[:type]}/knjdb_#{@opts[:type]}_columns" if (!@opts.has_key?(:require) or @opts[:require])
			@cols = Kernel.const_get("KnjDB_#{@opts[:type]}".to_sym).const_get(:Columns).new(
				:driver => @conn,
				:db => self
			)
		end
		
		return @cols
	end
	
	def indexes
		if !@indexes
			require "#{File.dirname(__FILE__)}/drivers/#{@opts[:type]}/knjdb_#{@opts[:type]}_indexes" if (!@opts.has_key?(:require) or @opts[:require])
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