class KnjDB_mysql
  attr_reader :knjdb, :conn, :conns, :escape_table, :escape_col, :escape_val, :esc_table
  attr_accessor :tables, :cols, :indexes
  
  def initialize(knjdb_ob)
    @knjdb = knjdb_ob
    @opts = @knjdb.opts
    @encoding = @opts[:encoding]
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
    @subtype = "mysql" if @subtype.to_s.length <= 0
    reconnect
  end
  
  def reconnect
    case @subtype
      when "mysql"
        @conn = Mysql.real_connect(@knjdb.opts[:host], @knjdb.opts[:user], @knjdb.opts[:pass], @knjdb.opts[:db], @port)
      when "mysql2"
        require "rubygems"
        require "mysql2"
        
        args = {
          :host => @knjdb.opts[:host],
          :username => @knjdb.opts[:user],
          :password => @knjdb.opts[:pass],
          :database => @knjdb.opts[:db],
          :port => @port,
          :symbolize_keys => true,
          :cache_rows => false
        }
        
        @query_args = {}
        @query_args.merge!(@knjdb.opts[:query_args]) if @knjdb.opts[:query_args]
        
        pos_args = [:as, :async, :cast_booleans, :database_timezone, :application_timezone, :cache_rows, :connect_flags, :cast]
        pos_args.each do |key|
          args[key] = @knjdb.opts[key] if @knjdb.opts.key?(key)
        end
        
        tries = 0
        begin
          tries += 1
          @conn = Mysql2::Client.new(args)
        rescue => e
          if tries <= 3
            if e.message == "Can't connect to local MySQL server through socket '/var/run/mysqld/mysqld.sock' (111)"
              sleep 1
              retry
            end
          end
          
          raise e
        end
      when "java"
        if !@jdbc_loaded
          require "java"
          require "/usr/share/java/mysql-connector-java.jar" if File.exists?("/usr/share/java/mysql-connector-java.jar")
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
  
  #For JQuery this scans if it is a data-manipulating query and executes the correct method on the driver.
  def query_conn(conn, str)
    case @subtype
      when "java"
        stmt = conn.createStatement
        
        if str.match(/^\s*(delete|update|create|drop\s+table|insert\s+into)\s+/i)
          return stmt.execute(str)
        else
          return stmt.executeQuery(str)
        end
      when "mysql", "mysql2"
        return conn.query(str)
      else
        raise "Could not figure out the way to execute the query on #{conn.class.name}."
    end
  end
  
  #Executes a query and returns the result.
  def query(string)
    string = string.to_s
    string = string.force_encoding("UTF-8") if @encoding == "utf8" and string.respond_to?(:force_encoding)
    tries = 0
    
    @mutex.synchronize do
      case @subtype
        when "mysql"
          begin
            tries += 1
            return KnjDB_mysql_result.new(self, @conn.query(string))
          rescue Mysql::Error => e
            if e.message == "MySQL server has gone away" or e.message == "Can't connect to local MySQL server through socket"
              raise e if tries >= 3
              sleep 0.5
              reconnect
              retry
            else
              raise e
            end
          end
        when "mysql2"
          begin
            tries += 1
            return KnjDB_mysql2_result.new(@conn.query(string, @query_args))
          rescue Mysql2::Error => e
            if e.message == "MySQL server has gone away" or e.message == "closed MySQL connection" or e.message == "Can't connect to local MySQL server through socket"
              raise e if tries >= 3
              sleep 0.5
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
        when "java"
          begin
            tries += 1
            return KnjDB_java_mysql_result.new(@knjdb, self.query_conn(@conn, string))
          rescue => e
            if e.to_s.index("No operations allowed after connection closed") != nil
              reconnect
              retry
            end
            
            print string
            raise e
          end
        else
          raise "Unknown subtype: '#{@subtype}'."
      end
    end
  end
  
  #Executes an unbuffered query and returns the result that can be used to access the data.
  def query_ubuf(str)
    @mutex.synchronize do
      case @subtype
        when "mysql"
          conn.query_with_result = false
          return KnjDB_mysql_unbuffered_result.new(@conn, @opts, @conn.query(str))
        when "mysql2"
          raise "MySQL2 does not support unbuffered queries yet! Waiting for :stream..."
        when "java"
          raise "Not implemented yet."
        else
          raise "Unknown subtype: '#{@subtype}'"
      end
    end
  end
  
  #Escapes a string to be safe to use in a query.
  def escape_alternative(string)
    case @subtype
      when "mysql"
        return @conn.escape_string(string.to_s)
      when "mysql2"
        return @conn.escape(string.to_s)
      when "java"
        return self.escape(string)
      else
        raise "Unknown subtype: '#{@subtype}'."
    end
  end
  
  #An alternative to the MySQL framework's escape. This is copied from the Ruby/MySQL framework at: http://www.tmtm.org/en/ruby/mysql/
  def escape(string)
    return string.to_s.gsub(/([\0\n\r\032\'\"\\])/) do
      case $1
        when "\0" then "\\0"
        when "\n" then "\\n"
        when "\r" then "\\r"
        when "\032" then "\\Z"
        else "\\" + $1
      end
    end
  end
  
  #Escapes a string to be safe to use as a column in a query.
  def esc_col(string)
    string = string.to_s
    raise "Invalid column-string: #{string}" if string.index(@escape_col) != nil
    return string
  end
  
  alias :esc_table :esc_col
  alias :esc :escape
  
  #Returns the last inserted ID for the connection.
  def lastID
    case @subtype
      when "mysql"
        @mutex.synchronize do
          return @conn.insert_id
        end
      when "mysql2"
        @mutex.synchronize do
          return @conn.last_id
        end
      when "java"
        data = self.query("SELECT LAST_INSERT_ID() AS id").fetch
        return data[:id] if data.key?(:id)
        raise "Could not figure out last inserted ID."
    end
  end
  
  #Closes the connection threadsafe.
  def close
    @mutex.synchronize do
      @conn.close
    end
  end
  
  #Destroyes the connection.
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
    sql = "INSERT INTO `#{self.esc_table(tablename)}` ("
    
    first = true
    arr_hashes.first.keys.each do |col_name|
      sql << "," if !first
      first = false if first
      sql << "`#{self.esc_col(col_name)}`"
    end
    
    sql << ") VALUES ("
    
    first = true
    arr_hashes.each do |hash|
      if first
        first = false
      else
        sql << "),("
      end
      
      first_key = true
      hash.each do |key, val|
        if first_key
          first_key = false
        else
          sql << ","
        end
        
        sql << "'#{self.escape(val)}'"
      end
    end
    
    sql << ")"
    
    self.query(sql)
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
    return self.fetch_hash_symbols if @driver.knjdb.opts[:return_keys] == "symbols"
    return self.fetch_hash_strings
  end
  
  def fetch_hash_strings
    @mutex.synchronize do
      return @result.fetch_hash
    end
  end
  
  def fetch_hash_symbols
    fetched = nil
    @mutex.synchronize do
      fetched = @result.fetch_row
    end
    
    return false if !fetched
    
    ret = {}
    count = 0
    @keys.each do |key|
      ret[key] = fetched[count]
      count += 1
    end
    
    return ret
  end
  
  def each
    while data = self.fetch_hash_symbols
      yield(data)
    end
  end
end

class KnjDB_mysql_unbuffered_result
  def initialize(conn, opts, result)
    @conn = conn
    @result = result
    
    if !opts.key?(:result) or opts[:result] == "hash"
      @as_hash = true
    elsif opts[:result] == "array"
      @as_hash = false
    else
      raise "Unknown type of result: '#{opts[:result]}'."
    end
  end
  
  def load_keys
    @keys = []
    keys = @res.fetch_fields
    keys.each do |key|
      @keys << key.name.to_sym
    end
  end
  
  def fetch
    if @enum
      begin
        ret = @enum.next
      rescue StopIteration
        @enum = nil
        @res = nil
      end
    end
    
    if !ret and !@res and !@enum
      begin
        @res = @conn.use_result
        @enum = @res.to_enum
        ret = @enum.next
      rescue Mysql::Error
        #Reset it to run non-unbuffered again and then return false.
        @conn.query_with_result = true
        return false
      rescue StopIteration
        sleep 0.1
        retry
      end
    end
    
    if !@as_hash
      return ret
    else
      self.load_keys if !@keys
      
      ret_h = {}
      @keys.each_index do |key_no|
        ret_h[@keys[key_no]] = ret[key_no]
      end
      
      return ret_h
    end
  end
  
  def each
    while data = self.fetch
      yield(data)
    end
  end
end

class KnjDB_mysql2_result
  def initialize(result)
    @result = result
  end
  
  def fetch
    @enum = @result.to_enum if !@enum
    
    begin
      return @enum.next
    rescue StopIteration
      return false
    end
  end
  
  def each(&block)
    @result.each(&block)
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
        ret[@keys[count]] = @result.string(count + 1).to_s.encode("utf-8")
      end
      
      return ret
    end
  end
  
  def each
    while data = self.fetch
      yield(data)
    end
  end
end