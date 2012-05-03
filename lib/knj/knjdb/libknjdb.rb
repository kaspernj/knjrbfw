class Knj::Db
  #Autoloader.
  def self.const_missing(name)
    require "#{$knjpath}knjdb/#{name.to_s.downcase}"
    return Knj::Db.const_get(name)
  end
  
  attr_reader :opts, :conn, :conns, :int_types
  
  def initialize(opts)
    require "#{$knjpath}threadhandler"
    
    self.setOpts(opts) if opts != nil
    
    @int_types = ["int", "bigint", "tinyint", "smallint", "mediumint"]
    
    if !@opts[:threadsafe]
      @mutex = Mutex.new
    end
    
    @debug = @opts[:debug]
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
    
    if RUBY_PLATFORM == "java"
      @opts[:subtype] = "java"
    elsif @opts[:type] == "sqlite3" and RUBY_PLATFORM.index("mswin32") != nil
      @opts[:subtype] = "ironruby"
    end
    
    self.connect
  end
  
  def connect
    if @opts[:threadsafe]
      @conns = Knj::Threadhandler.new
      
      @conns.on_spawn_new do
        self.spawn
      end
      
      @conns.on_inactive do |data|
        data[:obj].close
      end
      
      @conns.on_activate do |data|
        data[:obj].reconnect
      end
    else
      @conn = self.spawn
    end
  end
  
  def spawn
    raise "No type given." if !@opts[:type]
    
    fpaths = [
      "drivers/#{@opts[:type]}/knjdb_#{@opts[:type]}.rb",
      "libknjdb_#{@opts[:type]}.rb"
    ]
    fpaths.each do |fpath|
      rpath = "#{File.dirname(__FILE__)}/#{fpath}"
      
      if (!@opts.key?(:require) or @opts[:require]) and File.exists?(rpath)
        require rpath
        break
      end
    end
    
    return Kernel.const_get("KnjDB_#{@opts[:type]}").new(self)
  end
  
  def get_and_register_thread
    raise "KnjDB-object is not in threadding mode." if !@conns
    
    thread_cur = Thread.current
    tid = self.__id__
    thread_cur[:knjdb] = {} if !thread_cur[:knjdb]
    
    if thread_cur[:knjdb][tid]
      #An object has already been spawned - free that first to avoid endless "used" objects.
      self.free_thread
    end
    
    thread_cur[:knjdb][tid] = @conns.get_and_lock if !thread_cur[:knjdb][tid]
  end
  
  def free_thread
    thread_cur = Thread.current
    tid = self.__id__
    
    if thread_cur[:knjdb] and thread_cur[:knjdb].key?(tid)
      db = thread_cur[:knjdb][tid]
      thread_cur[:knjdb].delete(tid)
      @conns.free(db) if @conns
    end
  end
  
  #Clean up various memory-stuff if possible.
  def clean
    if @conns
      @conns.objects.each do |data|
        data[:object].clean if data[:object].respond_to?("clean")
      end
    elsif @conn
      @conn.clean if @conn.respond_to?("clean")
    end
  end
  
  def close
    @conn.close if @conn
    @conns.destroy if @conns
    
    @conn = nil
    @conns = nil
  end
  
  def clone_conn(args = {})
    return Knj::Db.new(@opts.clone.merge(args))
  end
  
  def copy_to(db, args = {})
    data["tables"].each do |table|
      table_args = nil
      table_args = args["tables"][table["name"].to_s] if args and args["tables"] and args["tables"][table["name"].to_s]
      next if table_args and table_args["skip"]
      table.delete("indexes") if table.key?("indexes") and args["skip_indexes"]
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
    self.conn_exec do |driver|
      sql = "INSERT INTO #{driver.escape_table}#{tablename.to_s}#{driver.escape_table} ("
      
      first = true
      arr_insert.each do |key, value|
        if first
          first = false
        else
          sql << ", "
        end
        
        sql << "#{driver.escape_col}#{key.to_s}#{driver.escape_col}"
      end
      
      sql << ") VALUES ("
      
      first = true
      arr_insert.each do |key, value|
        if first
          first = false
        else
          sql << ", "
        end
        
        sql << "#{driver.escape_val}#{driver.escape(value.to_s)}#{driver.escape_val}"
      end
      
      sql << ")"
      
      driver.query(sql)
      return driver.lastID if args[:return_id]
    end
  end
  
  def insert_multi(tablename, arr_hashes)
    self.conn_exec do |driver|
      if driver.respond_to?(:insert_multi)
        return false if arr_hashes.empty?
        driver.insert_multi(tablename, arr_hashes)
      else
        arr_hashes.each do |hash|
          self.insert(tablename, hash)
        end
      end
    end
  end
  
  def update(tablename, arr_update, arr_terms = {})
    return false if arr_update.empty?
    
    self.conn_exec do |driver|
      sql = ""
      sql << "UPDATE #{driver.escape_col}#{tablename.to_s}#{driver.escape_col} SET "
      
      first = true
      arr_update.each do |key, value|
        if first
          first = false
        else
          sql << ", "
        end
        
        sql << "#{driver.escape_col}#{key.to_s}#{driver.escape_col} = "
        sql << "#{driver.escape_val}#{driver.escape(value.to_s)}#{driver.escape_val}"
      end
      
      if arr_terms and arr_terms.length > 0
        sql << " WHERE #{self.makeWhere(arr_terms, driver)}"
      end
      
      driver.query(sql)
    end
  end
  
  #Makes a select from the given arguments: table-name, where-terms and other arguments as limits and orders. Also takes a block to avoid raping of memory.
  def select(tablename, arr_terms = nil, args = nil, &block)
    sql = ""
    
    self.conn_exec do |driver|
      sql = "SELECT * FROM #{driver.escape_table}#{tablename.to_s}#{driver.escape_table}"
      
      if arr_terms != nil and !arr_terms.empty?
        sql << " WHERE #{self.makeWhere(arr_terms, driver)}"
      end
      
      if args != nil
        if args["orderby"]
          sql << " ORDER BY "
          sql << args["orderby"]
        end
        
        if args["limit"]
          sql << " LIMIT " + args["limit"].to_s
        end
        
        if args["limit_from"] and args["limit_to"]
          raise "'limit_from' was not numeric: '#{args["limit_from"]}'." if !Knj::Php.is_numeric(args["limit_from"])
          raise "'limit_to' was not numeric: '#{args["limit_to"]}'." if !Knj::Php.is_numeric(args["limit_to"])
          
          sql << " LIMIT #{args["limit_from"]}, #{args["limit_to"]}"
        end
      end
    end
    
    return self.q(sql, &block)
  end
  
  def single(tablename, arr_terms = nil, args = {})
    args["limit"] = 1
    
    #Experienced very weird memory leak if this was not done by block. Maybe bug in Ruby 1.9.2? - knj
    self.select(tablename, arr_terms, args) do |data|
      return data
    end
    
    return false
  end
  
  alias :selectsingle :single
  
  def delete(tablename, arr_terms)
    self.conn_exec do |driver|
      sql = "DELETE FROM #{driver.escape_table}#{tablename}#{driver.escape_table}"
      
      if arr_terms != nil and !arr_terms.empty?
        sql << " WHERE #{self.makeWhere(arr_terms, driver)}"
      end
      
      driver.query(sql)
    end
    
    return nil
  end
  
  def makeWhere(arr_terms, driver)
    sql = ""
    
    first = true
    arr_terms.each do |key, value|
      if first
        first = false
      else
        sql << " AND "
      end
      
      if value.is_a?(Array)
        sql << "#{driver.escape_col}#{key}#{driver.escape_col} IN (#{Knj::ArrayExt.join(:arr => value, :sep => ",", :surr => "'", :callback => proc{|ele| self.esc(ele)})})"
      elsif value.is_a?(Hash)
        raise "Dont know how to handle hash."
      else
        sql << "#{driver.escape_col}#{key}#{driver.escape_col} = #{driver.escape_val}#{driver.escape(value)}#{driver.escape_val}"
      end
    end
    
    return sql
  end
  
  #Returns a driver-object based on the current thread and free driver-objects.
  def conn_exec
    if Thread.current[:knjdb]
      tid = self.__id__
      
      if Thread.current[:knjdb].key?(tid)
        yield(Thread.current[:knjdb][tid])
        return nil
      end
    end
    
    if @conns
      conn = @conns.get_and_lock
      
      begin
        yield(conn)
        return nil
      ensure
        @conns.free(conn)
      end
    elsif @conn
      begin
        @mutex.synchronize do
          yield(@conn)
          return nil
        end
      rescue ThreadError => e
        if e.message != "deadlock; recursive locking"
          yield(@conn)
          return nil
        else
          raise e
        end
      end
    end
    
    raise "Could not figure out how to find a driver to use?"
  end
  
  #Executes a query and returns the result.
  def query(string)
    if @debug
      print "SQL: #{string}\n"
      
      if @debug.is_a?(Fixnum) and @debug >= 2
        print caller.join("\n")
        print "\n"
      end
    end
    
    self.conn_exec do |driver|
      return driver.query(string)
    end
  end
  
  #Execute an ubuffered query and returns the result.
  def query_ubuf(string, &block)
    ret = nil
    
    self.conn_exec do |driver|
      ret = driver.query_ubuf(string, &block)
    end
    
    if block
      ret.each(&block)
      return nil
    end
    
    return ret
  end
  
  #Clones the connection, executes a unbuffered query and closes the connection again.
  def cloned_conn(args = nil, &block)
    clone_conn_args = {
      :threadsafe => false
    }
    
    clone_conn_args.merge!(args[:clone_args]) if args and args[:clone_args]
    dbconn = self.clone_conn(clone_conn_args)
    
    begin
      yield(dbconn)
    ensure
      dbconn.close
    end
  end
  
  #Executes a query and returns the result. If a block is given the result is iterated over that block instead and it returns nil.
  def q(str, args = nil, &block)
    #If the query should be executed in a new connection unbuffered.
    if args
      if args[:cloned_ubuf]
        raise "No block given." if !block
        
        self.cloned_conn(:clone_args => args[:clone_args]) do |cloned_conn|
          ret = cloned_conn.query_ubuf(str)
          ret.each(&block)
        end
        
        return nil
      else
        raise "Invalid arguments given: '#{args}'."
      end
    end
    
    ret = self.query(str)
    
    if block
      ret.each(&block)
      return nil
    end
    
    return ret
  end
  
  #Returns the last inserted ID.
  def lastID
    self.conn_exec do |driver|
      return driver.lastID
    end
  end
  
  alias :last_id :lastID
  
  #Escapes a string to be safe-to-use in a query-string.
  def escape(string)
    self.conn_exec do |driver|
      return driver.escape(string)
    end
  end
  
  alias :esc :escape
  
  def esc_col(str)
    self.conn_exec do |driver|
      return driver.esc_col(str)
    end
  end
  
  def esc_table(str)
    self.conn_exec do |driver|
      return driver.esc_table(str)
    end
  end
  
  def enc_table
    if !@enc_table
      self.conn_exec do |driver|
        @enc_table = driver.escape_table
      end
    end
    
    return @enc_table
  end
  
  def enc_col
    if !@enc_col
      self.conn_exec do |driver|
        @enc_col = driver.escape_col
      end
    end
    
    return @enc_col
  end
  
  def date_out(date_obj = Knj::Datet.new, args = {})
    return Knj::Datet.in(date_obj).dbstr(args)
  end
  
  def date_in(date_obj)
    return Knj::Datet.in(date_obj)
  end
  
  #Returns the table-module and spawns it if it isnt already spawned.
  def tables
    conn_exec do |driver|
      if !@tables
        require "#{File.dirname(__FILE__)}/drivers/#{@opts[:type]}/knjdb_#{@opts[:type]}_tables" if (!@opts.key?(:require) or @opts[:require])
        @tables = Kernel.const_get("KnjDB_#{@opts[:type]}".to_sym).const_get(:Tables).new(
          :db => self
        )
      end
      
      return @tables
    end
  end
  
  #Returns the columns-module and spawns it if it isnt already spawned.
  def cols
    if !@cols
      require "#{File.dirname(__FILE__)}/drivers/#{@opts[:type]}/knjdb_#{@opts[:type]}_columns" if (!@opts.key?(:require) or @opts[:require])
      @cols = Kernel.const_get("KnjDB_#{@opts[:type]}".to_sym).const_get(:Columns).new(
        :db => self
      )
    end
    
    return @cols
  end
  
  #Returns the index-module and spawns it if it isnt already spawned.
  def indexes
    if !@indexes
      require "#{File.dirname(__FILE__)}/drivers/#{@opts[:type]}/knjdb_#{@opts[:type]}_indexes" if (!@opts.key?(:require) or @opts[:require])
      @indexes = Kernel.const_get("KnjDB_#{@opts[:type]}".to_sym).const_get(:Indexes).new(
        :db => self
      )
    end
    
    return @indexes
  end
  
  def method_missing(method_name, *args)
    self.conn_exec do |driver|
      if driver.respond_to?(method_name.to_sym)
        return driver.send(method_name, *args)
      end
    end
    
    raise "Method not found: #{method_name}"
  end
  
  #Beings a transaction and commits when the block ends.
  def transaction
    self.query("START TRANSACTION")
    
    begin
      yield(self)
    ensure
      self.query("COMMIT")
    end
  end
end