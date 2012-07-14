require "rubygems"

if !Kernel.const_defined?(:Wref)
  require "wref"
end

if !Kernel.const_defined?(:Datet)
  require "datet"
end

#A wrapper of several possible database-types.
#
#===Examples
# db = Knj::Db.new(:type => "mysql", :subtype => "mysql2", :db => "mysql", :user => "user", :pass => "password")
# mysql_table = db.tables['mysql']
# name = mysql_table.name
# cols = mysql_table.columns
#
# db = Knj::Db.new(:type => "sqlite3", :path => "some_db.sqlite3")
#
# db.q("SELECT * FROM users") do |data|
#   print data[:name]
# end
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
      require "monitor"
      @mutex = Monitor.new
    end
    
    @debug = @opts[:debug]
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
  
  #Actually connects to the database. This is useually done automatically.
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
  
  #Spawns a new driver (useally done automatically).
  #===Examples
  # driver_instance = db.spawn
  def spawn
    raise "No type given (#{@opts.keys.join(",")})." if !@opts[:type]
    
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
  
  #Registers a driver to the current thread.
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
    
    #If block given then be ensure to free thread after yielding.
    if block_given?
      begin
        yield
      ensure
        self.free_thread
      end
    end
  end
  
  #Frees the current driver from the current thread.
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
  
  #The all driver-database-connections.
  def close
    @conn.close if @conn
    @conns.destroy if @conns
    
    @conn = nil
    @conns = nil
  end
  
  #Clones the current database-connection with possible extra arguments.
  def clone_conn(args = {})
    conn = Knj::Db.new(@opts.clone.merge(args))
    
    if block_given?
      begin
        yield(conn)
      ensure
        conn.close
      end
      
      return nil
    else
      return conn
    end
  end
  
  #Copies the content of the current database to another instance of Knj::Db.
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
  
  #Returns the data of this database in a hash.
  #===Examples
  # data = db.data
  # tables_hash = data['tables']
  def data
    tables_ret = []
    tables.list.each do |name, table|
      tables_ret << table.data
    end
    
    return {
      "tables" => tables_ret
    }
  end
  
  #Simply inserts data into a table.
  #
  #===Examples
  # db.insert(:users, {:name => "John", :lastname => "Doe"})
  # id = db.insert(:users, {:name => "John", :lastname => "Doe"}, :return_id => true)
  # sql = db.insert(:users, {:name => "John", :lastname => "Doe"}, :return_sql => true) #=> "INSERT INTO `users` (`name`, `lastname`) VALUES ('John', 'Doe')"
  def insert(tablename, arr_insert, args = nil)
    self.conn_exec do |driver|
      sql = "INSERT INTO #{driver.escape_table}#{tablename.to_s}#{driver.escape_table}"
      
      if !arr_insert or arr_insert.empty?
        #This is the correct syntax for inserting a blank row in MySQL.
        sql << " VALUES ()"
      else
        sql << " ("
        
        first = true
        arr_insert.each do |key, value|
          if first
            first = false
          else
            sql << ", "
          end
          
          sql << "#{driver.escape_col}#{key.to_s}#{driver.escape_col}"
        end
        
        sql << ")  VALUES ("
        
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
      end
      
      return sql if args and args[:return_sql]
      driver.query(sql)
      return driver.lastID if args and args[:return_id]
      return nil
    end
  end
  
  #Simply and optimal insert multiple rows into a table in a single query. Uses the drivers functionality if supported or inserts each row manually.
  #
  #===Examples
  # db.insert_multi(:users, [
  #   {:name => "John", :lastname => "Doe"},
  #   {:name => "Kasper", :lastname => "Johansen"}
  # ])
  def insert_multi(tablename, arr_hashes, args = nil)
    return false if arr_hashes.empty?
    
    self.conn_exec do |driver|
      if driver.respond_to?(:insert_multi)
        if args and args[:return_sql]
          return [driver.insert_multi(tablename, arr_hashes, args)]
        else
          return driver.insert_multi(tablename, arr_hashes, args)
        end
      else
        ret = [] if args and (args[:return_id] or args[:return_sql])
        arr_hashes.each do |hash|
          if ret
            ret << self.insert(tablename, hash, args)
          else
            self.insert(tablename, hash, args)
          end
        end
        
        if ret
          return ret
        else
          return nil
        end
      end
    end
  end
  
  #Simple updates rows.
  #
  #===Examples
  # db.update(:users, {:name => "John"}, {:lastname => "Doe"})
  def update(tablename, arr_update, arr_terms = {}, args = nil)
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
        
        #Convert dates to valid dbstr.
        value = self.date_out(value) if value.is_a?(Datet) or value.is_a?(Time)
        
        sql << "#{driver.escape_col}#{key.to_s}#{driver.escape_col} = "
        sql << "#{driver.escape_val}#{driver.escape(value.to_s)}#{driver.escape_val}"
      end
      
      if arr_terms and arr_terms.length > 0
        sql << " WHERE #{self.makeWhere(arr_terms, driver)}"
      end
      
      return sql if args and args[:return_sql]
      driver.query(sql)
    end
  end
  
  #Makes a select from the given arguments: table-name, where-terms and other arguments as limits and orders. Also takes a block to avoid raping of memory.
  def select(tablename, arr_terms = nil, args = nil, &block)
    #Set up vars.
    sql = ""
    args_q = nil
    select_sql = "*"
    
    #Give 'cloned_ubuf' argument to 'q'-method.
    if args and args[:cloned_ubuf]
      args_q = {:cloned_ubuf => true}
    end
    
    #Set up IDQuery-stuff if that is given in arguments.
    if args and args[:idquery]
      if args[:idquery] == true
        select_sql = "`id`"
        col = :id
      else
        select_sql = "`#{self.esc_col(args[:idquery])}`"
        col = args[:idquery]
      end
    end
    
    #Get the driver and generate SQL.
    self.conn_exec do |driver|
      sql = "SELECT #{select_sql} FROM #{driver.escape_table}#{tablename.to_s}#{driver.escape_table}"
      
      if arr_terms != nil and !arr_terms.empty?
        sql << " WHERE #{self.makeWhere(arr_terms, driver)}"
      end
      
      if args != nil
        if args["orderby"]
          sql << " ORDER BY #{args["orderby"]}"
        end
        
        if args["limit"]
          sql << " LIMIT #{args["limit"]}"
        end
        
        if args["limit_from"] and args["limit_to"]
          raise "'limit_from' was not numeric: '#{args["limit_from"]}'." if !Knj::Php.is_numeric(args["limit_from"])
          raise "'limit_to' was not numeric: '#{args["limit_to"]}'." if !Knj::Php.is_numeric(args["limit_to"])
          sql << " LIMIT #{args["limit_from"]}, #{args["limit_to"]}"
        end
      end
    end
    
    #Do IDQuery if given in arguments.
    if args and args[:idquery]
      res = Knj::Db::Idquery.new(:db => self, :table => tablename, :query => sql, :col => col, &block)
    else
      res = self.q(sql, args_q, &block)
    end
    
    #Return result if a block wasnt given.
    if block
      return nil
    else
      return res
    end
  end
  
  #Returns a single row from a database.
  #
  #===Examples
  # row = db.single(:users, {:lastname => "Doe"})
  def single(tablename, arr_terms = nil, args = {})
    args["limit"] = 1
    
    #Experienced very weird memory leak if this was not done by block. Maybe bug in Ruby 1.9.2? - knj
    self.select(tablename, arr_terms, args) do |data|
      return data
    end
    
    return false
  end
  
  alias :selectsingle :single
  
  #Deletes rows from the database.
  #
  #===Examples
  # db.delete(:users, {:lastname => "Doe"})
  def delete(tablename, arr_terms, args = nil)
    self.conn_exec do |driver|
      sql = "DELETE FROM #{driver.escape_table}#{tablename}#{driver.escape_table}"
      
      if arr_terms != nil and !arr_terms.empty?
        sql << " WHERE #{self.makeWhere(arr_terms, driver)}"
      end
      
      return sql if args and args[:return_sql]
      driver.query(sql)
    end
    
    return nil
  end
  
  #Internally used to generate SQL.
  #
  #===Examples
  # sql = db.makeWhere({:lastname => "Doe"}, driver_obj)
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
        raise "Array for column '#{key}' was empty." if value.empty?
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
  #
  #===Examples
  # db.conn_exec do |driver|
  #   str = driver.escape('something̈́')
  # end
  def conn_exec
    if tcur = Thread.current and tcur[:knjdb]
      tid = self.__id__
      
      if tcur[:knjdb].key?(tid)
        yield(tcur[:knjdb][tid])
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
      @mutex.synchronize do
        yield(@conn)
        return nil
      end
    end
    
    raise "Could not figure out how to find a driver to use?"
  end
  
  #Executes a query and returns the result.
  #
  #===Examples
  # res = db.query('SELECT * FROM users')
  # while data = res.fetch
  #   print data[:name]
  # end
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
  #
  #===Examples
  # db.query_ubuf('SELECT * FROM users') do |data|
  #   print data[:name]
  # end
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
  
  #Clones the connection, executes the given block and closes the connection again.
  #
  #===Examples
  # db.cloned_conn do |conn|
  #   conn.q('SELCET * FROM users') do |data|
  #     print data[:name]
  #   end
  # end
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
  #
  #===Examples
  # db.q('SELECT * FROM users') do |data|
  #   print data[:name]
  # end
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
  
  #Yields a query-buffer and flushes at the end of the block given.
  def q_buffer(&block)
    Knj::Db::Query_buffer.new(:db => self, &block)
    return nil
  end
  
  #Returns the last inserted ID.
  #
  #===Examples
  # id = db.last_id
  def lastID
    self.conn_exec do |driver|
      return driver.lastID
    end
  end
  
  alias :last_id :lastID
  
  #Escapes a string to be safe-to-use in a query-string.
  #
  #===Examples
  # db.q("INSERT INTO users (name) VALUES ('#{db.esc('John')}')")
  def escape(string)
    self.conn_exec do |driver|
      return driver.escape(string)
    end
  end
  
  alias :esc :escape
  
  #Escapes the given string to be used as a column.
  def esc_col(str)
    self.conn_exec do |driver|
      return driver.esc_col(str)
    end
  end
  
  #Escapes the given string to be used as a table.
  def esc_table(str)
    self.conn_exec do |driver|
      return driver.esc_table(str)
    end
  end
  
  #Returns the sign for surrounding the string that should be used as a table.
  def enc_table
    if !@enc_table
      self.conn_exec do |driver|
        @enc_table = driver.escape_table
      end
    end
    
    return @enc_table
  end
  
  #Returns the sign for surrounding the string that should be used as a column.
  def enc_col
    if !@enc_col
      self.conn_exec do |driver|
        @enc_col = driver.escape_col
      end
    end
    
    return @enc_col
  end
  
  #Returns a string which can be used in SQL with the current driver.
  #===Examples
  # str = db.date_out(Time.now) #=> "2012-05-20 22:06:09"
  def date_out(date_obj = Datet.new, args = {})
    conn_exec do |driver|
      if driver.respond_to?(:date_out)
        return driver.date_out(date_obj, args)
      end
    end
    
    return Datet.in(date_obj).dbstr(args)
  end
  
  #Takes a valid date-db-string and converts it into a Datet.
  #===Examples
  # db.date_in('2012-05-20 22:06:09') #=> 2012-05-20 22:06:09 +0200
  def date_in(date_obj)
    conn_exec do |driver|
      if driver.respond_to?(:date_in)
        return driver.date_in(date_obj)
      end
    end
    
    return Datet.in(date_obj)
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
  
  #Returns the SQLSpec-module and spawns it if it isnt already spawned.
  def sqlspecs
    if !@sqlspecs
      require "#{File.dirname(__FILE__)}/drivers/#{@opts[:type]}/knjdb_#{@opts[:type]}_sqlspecs" if (!@opts.key?(:require) or @opts[:require])
      @sqlspecs = Kernel.const_get("KnjDB_#{@opts[:type]}".to_sym).const_get(:Sqlspecs).new(
        :db => self
      )
    end
    
    return @sqlspecs
  end
  
  #Beings a transaction and commits when the block ends.
  #
  #===Examples
  # db.transaction do |db|
  #   db.insert(:users, {:name => "John"})
  #   db.insert(:users, {:name => "Kasper"})
  # end
  def transaction(&block)
    self.conn_exec do |driver|
      driver.transaction(&block)
    end
  end
  
  #Returns the sign to be used for surrounding tables.
  def col_table
    return "`"
  end
  
  #Optimizes all tables in the database.
  def optimize(args = nil)
    STDOUT.puts "Beginning optimization of database." if @debug or (args and args[:debug])
    self.tables.list do |table|
      STDOUT.puts "Optimizing table: '#{table.name}'." if @debug or (args and args[:debug])
      table.optimize
    end
    
    return nil
  end
  
  #Proxies the method to the driver.
  #
  #===Examples
  # db.method_on_driver
  def method_missing(method_name, *args)
    self.conn_exec do |driver|
      if driver.respond_to?(method_name.to_sym)
        return driver.send(method_name, *args)
      end
    end
    
    raise "Method not found: #{method_name}"
  end
end