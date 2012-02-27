require "#{$knjpath}wref"

class KnjDB_mysql::Tables
  attr_reader :db, :driver, :list
  attr_accessor :list_should_be_reloaded
  
  def initialize(args)
    @args = args
    @db = @args[:db]
    @driver = @args[:driver]
    @subtype = @db.opts[:subtype]
    @list_mutex = Mutex.new
    @list = Knj::Wref_map.new
    @list_should_be_reloaded = true
  end
  
  def clean
    @list.clean
  end
  
  #Returns a table by the given table-name.
  def [](table_name)
    table_name = table_name.to_s
    
    begin
      return @list[table_name]
    rescue WeakRef::RefError
      #ignore.
    end
    
    self.list do |table_obj|
      return table_obj if table_obj.name == table_name
    end
    
    raise Knj::Errors::NotFound.new("Table was not found: #{table_name}.")
  end
  
  def list(args = {})
    ret = {} unless block_given?
    
    @list_mutex.synchronize do
      @db.q("SHOW TABLE STATUS") do |d_tables|
        obj = @list.get!(d_tables[:Name])
        
        if !obj
          obj = KnjDB_mysql::Tables::Table.new(
            :db => @db,
            :driver => @driver,
            :data => d_tables,
            :tables => self
          )
          @list[d_tables[:Name]] = obj
        end
        
        if block_given?
          yield(obj)
        else
          ret[d_tables[:Name]] = obj
        end
      end
    end
    
    if block_given?
      return nil
    else
      return ret
    end
  end
  
  def create(name, data)
    raise "No columns was given for '#{name}'." if !data["columns"] or data["columns"].empty?
    
    sql = "CREATE TABLE `#{name}` ("
    
    first = true
    data["columns"].each do |col_data|
      sql << ", " if !first
      first = false if first
      col_data.delete("after") if col_data["after"]
      sql << @db.cols.data_sql(col_data)
    end
    
    sql << ")"
    
    @db.query(sql)
    @list_should_be_reloaded = true
    
    if data["indexes"]
      table_obj = self[name]
      table_obj.create_indexes(data["indexes"])
    end
  end
end

class KnjDB_mysql::Tables::Table
  attr_accessor :list
  
  def initialize(args)
    @args = args
    @db = args[:db]
    @driver = args[:driver]
    @data = args[:data]
    @subtype = @db.opts[:subtype]
    @list = Knj::Wref_map.new
    @indexes_list = Knj::Wref_map.new
    
    raise "Could not figure out name from: '#{@data}'." if !@data[:Name]
  end
  
  def name
    return @data[:Name]
  end
  
  def drop
    sql = "DROP TABLE `#{self.name}`"
    @db.query(sql)
  end
  
  def optimize
    @db.query("OPTIMIZE TABLE `#{self.name}`")
    return self
  end
  
  def column(name)
    name = name.to_s
    
    begin
      return @list[name]
    rescue WeakRef::RefError
      #ignore.
    end
    
    self.columns do |col|
      return col if col.name == name
    end
    
    raise Knj::Errors::NotFound.new("Column not found: '#{name}'.")
  end
  
  def columns
    @db.cols
    ret = {}
    sql = "SHOW FULL COLUMNS FROM `#{self.name}`"
    
    @db.q(sql) do |d_cols|
      obj = @list.get!(d_cols[:Field])
      
      if !obj
        obj = KnjDB_mysql::Columns::Column.new(
          :table_name => self.name,
          :db => @db,
          :driver => @driver,
          :data => d_cols
        )
        @list[d_cols[:Field]] = obj
      end
      
      if block_given?
        yield(obj)
      else
        ret[d_cols[:Field]] = obj
      end
    end
    
    return ret
  end
  
  def indexes
    @db.indexes
    ret = {}
    
    @db.q("SHOW INDEX FROM `#{self.name}`") do |d_indexes|
      next if d_indexes[:Key_name] == "PRIMARY"
      
      obj = @indexes_list.get!(d_indexes[:Key_name])
      
      if !obj
        obj = KnjDB_mysql::Indexes::Index.new(
          :table_name => self.name,
          :db => @db,
          :driver => @driver,
          :data => d_indexes
        )
        obj.columns << d_indexes[:Column_name]
        @indexes_list[d_indexes[:Key_name]] = obj
      end
      
      if block_given?
        yield(obj)
      else
        ret[d_indexes[:Key_name]] = obj
      end
    end
    
    return ret
  end
  
  def index(name)
    name = name.to_s
    
    begin
      return @indexes_list[name]
    rescue WeakRef::RefError
      #ignore.
    end
    
    self.indexes do |index|
      return index if index.name == name
    end
    
    raise Knj::Errors::NotFound.new("Index not found: #{name}.")
  end
  
  def create_columns(col_arr)
    col_arr.each do |col_data|
      sql = "ALTER TABLE `#{self.name}` ADD COLUMN #{@db.cols.data_sql(col_data)};"
      @db.query(sql)
    end
  end
  
  def create_indexes(index_arr)
    index_arr.each do |index_data|
      if index_data.is_a?(String)
        index_data = {"name" => index_data, "columns" => [index_data]}
      end
      
      raise "No name was given." if !index_data.key?("name") or index_data["name"].strip.length <= 0
      raise "No columns was given on index: '#{index_data["name"]}'." if !index_data["columns"] or index_data["columns"].empty?
      
      sql = "CREATE"
      sql << " UNIQUE" if index_data["unique"]
      sql << " INDEX #{@db.escape_col}#{@db.esc_col(index_data["name"])}#{@db.escape_col} ON #{@db.escape_table}#{@db.esc_table(self.name)}#{@db.escape_table} ("
      
      first = true
      index_data["columns"].each do |col_name|
        sql << ", " if !first
        first = false if first
        
        sql << "#{@db.escape_col}#{@db.esc_col(col_name)}#{@db.escape_col}"
      end
      
      sql << ")"
      
      @db.query(sql)
    end
  end
  
  def rename(newname)
    oldname = self.name
    @db.query("ALTER TABLE `#{oldname}` RENAME TO `#{newname}`")
    @args[:tables].list[newname] = self
    @args[:tables].list.delete(oldname)
    @data[:Name] = newname
  end
  
  def truncate
    @db.query("TRUNCATE `#{self.name}`")
    return self
  end
  
  def data
    ret = {
      "name" => name,
      "columns" => [],
      "indexes" => []
    }
    
    columns.each do |name, column|
      ret["columns"] << column.data
    end
    
    indexes.each do |name, index|
      ret["indexes"] << index.data if name != "PRIMARY"
    end
    
    return ret
  end
  
  def insert(data)
    @db.insert(self.name, data)
  end
end