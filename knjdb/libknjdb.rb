module Knj
	class Db
		def initialize(opts)
			if (opts != nil)
				self.setOpts(opts)
			end
		end
		
		def opts
			return @opts
		end
		
		def col_table
			return "`"
		end
		
		def setOpts(arr_opts)
			@opts = {}
			
			arr_opts.each do |pair|
				@opts[pair[0]] = pair[1];
			end
			
			self.connect()
		end
		
		def connect
			require(File.dirname(__FILE__) + "/libknjdb_" + @opts["type"] + ".rb")
			@conn = Kernel.const_get("KnjDB_" + @opts["type"]).new(self)
		end
		
		def close
			@conn.close
		end
		
		def insert(tablename, arr_insert)
			sql = "INSERT INTO "
			sql += @conn.escape_table
			sql += tablename
			sql += @conn.escape_table
			sql += " ("
			
			first = true
			arr_insert.each do |pair|
				if (first)
					first = false
				else
					sql += ", "
				end
				
				sql += @conn.escape_col
				sql += pair[0]
				sql += @conn.escape_col
			end
			
			sql += ") VALUES ("
			
			first = true
			arr_insert.each do |pair|
				if (first)
					first = false
				else
					sql += ", "
				end
				
				sql += @conn.escape_val
				sql += @conn.escape(pair[1])
				sql += @conn.escape_val
			end
			
			sql += ")"
			
			@conn.query(sql)
		end
		
		def update(tablename, arr_update, arr_terms = {})
			sql = "UPDATE "
			sql += @conn.escape_col
			sql += tablename
			sql += @conn.escape_col
			sql += " SET "
			
			first = true;
			arr_update.each do |pair|
				if (first)
					first = false
				else
					sql += ", "
				end
				
				sql += @conn.escape_col
				sql += pair[0].to_s
				sql += @conn.escape_col
				sql += " = "
				sql += @conn.escape_val
				sql += @conn.escape(pair[1].to_s)
				sql += @conn.escape_val
			end
			
			if arr_terms and arr_terms.length > 0
				sql += " WHERE "
				sql += self.makeWhere(arr_terms)
			end
			
			self.query(sql)
		end
		
		def select(tablename, arr_terms = nil, args = nil)
			sql = "SELECT * FROM "
			sql += @conn.escape_table
			sql += tablename.to_s
			sql += @conn.escape_table
			
			if (arr_terms != nil)
				sql += " WHERE "
				sql += self.makeWhere(arr_terms)
			end
			
			if (args != nil)
				if (args["orderby"])
					sql += " ORDER BY "
					sql += args["orderby"]
				end
				
				if (args["limit"])
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
			sql = "DELETE FROM "
			sql += @conn.escape_table
			sql += tablename
			sql += @conn.escape_table
			
			if (arr_terms != nil)
				sql += " WHERE "
				sql += self.makeWhere(arr_terms)
			end
			
			self.query(sql)
		end
		
		def makeWhere(arr_terms)
			sql = ""
			
			first = true
			arr_terms.each do |pair|
				if (first)
					first = false
				else
					sql += " AND "
				end
				
				sql += @conn.escape_col
				sql += pair[0].to_s
				sql += @conn.escape_col
				sql += " = "
				sql += @conn.escape_val
				sql += @conn.escape(pair[1])
				sql += @conn.escape_val
			end
			
			return sql
		end
		
		def query(string)
			return @conn.query(string)
		end
		
		def lastID
			return @conn.lastID
		end
		
		def last_id
			return self.lastID
		end
		
		def escape(string)
			return @conn.escape(string)
		end
		
		def esc(string)
			return self.escape(string)
		end
	end
end