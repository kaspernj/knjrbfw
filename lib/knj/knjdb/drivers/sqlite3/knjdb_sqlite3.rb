class KnjDB_sqlite3
  attr_reader :knjdb, :conn, :escape_table, :escape_col, :escape_val, :esc_table, :esc_col, :symbolize
  attr_accessor :tables, :cols, :indexes
  
  def initialize(knjdb_ob)
    @escape_table = "`"
    @escape_col = "`"
    @escape_val = "'"
    @esc_table = "`"
    @esc_col = "`"
    
    @knjdb = knjdb_ob
    @path = @knjdb.opts[:path] if @knjdb.opts[:path]
    @path = @knjdb.opts["path"] if @knjdb.opts["path"]
    @symbolize = true if !@knjdb.opts.has_key?(:return_keys) or @knjdb.opts[:return_keys] == "symbols"
    
    @knjdb.opts[:subtype] = "java" if !@knjdb.opts.key?(:subtype) and RUBY_ENGINE == "jruby"
    raise "No path was given." if !@path
    
    if @knjdb.opts[:subtype] == "java"
      if @knjdb.opts[:sqlite_driver]
        require @knjdb.opts[:sqlite_driver]
      else
        require "#{File.dirname(__FILE__)}/../../sqlitejdbc-v056.jar"
      end
      
      require "java"
      import "org.sqlite.JDBC"
      @conn = java.sql.DriverManager::getConnection("jdbc:sqlite:#{@knjdb.opts[:path]}")
      @stat = @conn.createStatement
    elsif @knjdb.opts[:subtype] == "rhodes"
      @conn = SQLite3::Database.new(@path, @path)
    else
      @conn = SQLite3::Database.open(@path)
      @conn.results_as_hash = true
      @conn.type_translation = false
    end
  end
  
  def query(string)
    begin
      if @knjdb.opts[:subtype] == "rhodes"
        res = @conn.execute(string, string)
      elsif @knjdb.opts[:subtype] == "java"
        begin
          return KnjDB_sqlite3_result_java.new(self, @stat.executeQuery(string))
        rescue java.sql.SQLException => e
          if e.message == "java.sql.SQLException: query does not return ResultSet"
            #ignore it.
          else
            raise e
          end
        end
      else
        res = @conn.execute(string)
      end
    rescue Exception => e
      print "SQL: #{string}\n"
      raise e
    end
    
    return KnjDB_sqlite3_result.new(self, res)
  end
  
  def escape(string)
    #This code is taken directly from the documentation so we dont have to rely on the SQLite3::Database class. This way it can also be used with JRuby and IronRuby...
    #http://sqlite-ruby.rubyforge.org/classes/SQLite/Database.html
    return string.to_s.gsub(/'/, "''")
  end
  
  def esc_col(string)
    string = string.to_s
    raise "Invalid column-string: #{string}" if string.index(@escape_col) != nil
    return string
  end
  
  alias :esc_table :esc_col
  alias :esc :escape
  
  def lastID
    return @conn.last_insert_row_id if @conn.respond_to?(:last_insert_row_id)
    return self.query("SELECT last_insert_rowid() AS id").fetch[:id].to_i
  end
  
  def close
    @conn.close
  end
end

class KnjDB_sqlite3_result_java
  def initialize(driver, rs)
    @rs = rs
    @index = 0
    @retkeys = driver.knjdb.opts[:return_keys]
    
    if rs
      @metadata = rs.getMetaData
      @columns_count = @metadata.getColumnCount
    end
  end
  
  def fetch
    if !@rs.next
      return false
    end
    
    tha_return = {}
    for i in (1..@columns_count)
      col_name = @metadata.getColumnName(i)
      col_name = col_name.to_s.to_sym if @retkeys == "symbols"
      
      tha_return.store(col_name, @rs.getString(i))
    end
    
    return tha_return
  end
end

class KnjDB_sqlite3_result
  def initialize(driver, result_array)
    @result_array = result_array
    @index = 0
    @retkeys = driver.knjdb.opts[:return_keys]
  end
  
  def fetch
    tha_return = @result_array[@index]
    return false if !tha_return
    @index += 1
    
    ret = {}
    tha_return.each do |key, val|
      if Knj::Php::is_numeric(key)
        #do nothing.
      elsif @retkeys == "symbols" and !key.is_a?(Symbol)
        ret[key.to_sym] = val
      else
        ret[key] = val
      end
    end
    
    return ret
  end
end