#This class handels various MySQL-table-specific behaviour.
class KnjDB_mysql::Tables
  attr_reader :db, :list
  
  #Constructor. This should not be called manually.
  def initialize(args)
    @args = args
    @db = @args[:db]
    @subtype = @db.opts[:subtype]
    @list_mutex = Mutex.new
    @list = Wref_map.new
    @list_should_be_reloaded = true
  end
  
  #Cleans the wref-map.
  def clean
    @list.clean
  end
  
  #Returns a table by the given table-name.
  def [](table_name)
    table_name = table_name.to_s
    
    begin
      return @list[table_name]
    rescue Wref::Recycled
      #ignore.
    end
    
    self.list(:name => table_name) do |table_obj|
      return table_obj if table_obj.name == table_name
    end
    
    raise Knj::Errors::NotFound.new("Table was not found: #{table_name}.")
  end
  
  #Yields the tables of the current database.
  def list(args = {})
    ret = {} unless block_given?
    
    sql = "SHOW TABLE STATUS"
    if args[:name]
      sql << " WHERE `Name` = '#{@db.esc(args[:name])}'"
    end
    
    @list_mutex.synchronize do
      @db.q(sql) do |d_tables|
        obj = @list.get!(d_tables[:Name])
        
        if !obj
          obj = KnjDB_mysql::Tables::Table.new(
            :db => @db,
            :data => d_tables
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
  
  #Creates a new table by the given name and data.
  def create(name, data, args = nil)
    raise "No columns was given for '#{name}'." if !data["columns"] or data["columns"].empty?
    
    sql = "CREATE TABLE `#{name}` ("
    
    first = true
    data["columns"].each do |col_data|
      sql << ", " if !first
      first = false if first
      col_data.delete("after") if col_data["after"]
      sql << @db.cols.data_sql(col_data)
    end
    
    if data["indexes"]
      sql << ", "
      sql << KnjDB_mysql::Tables::Table.create_indexes(data["indexes"], {
        :db => @db,
        :return_sql => true,
        :create => false,
        :on_table => false,
        :table_name => name
      })
    end
    
    sql << ")"
    
    return [sql] if args and args[:return_sql]
    @db.query(sql)
  end
end

class KnjDB_mysql::Tables::Table
  attr_accessor :list
  
  def initialize(args)
    @args = args
    @db = args[:db]
    @data = args[:data]
    @subtype = @db.opts[:subtype]
    @list = Wref_map.new
    @indexes_list = Wref_map.new
    
    raise "Could not figure out name from: '#{@data}'." if @data[:Name].to_s.strip.length <= 0
  end
  
  def reload
    @data = @db.q("SHOW TABLE STATUS WHERE `Name` = '#{@db.esc(self.name)}'").fetch
  end
  
  #Used to validate in Knj::Wrap_map.
  def __object_unique_id__
    return @data[:Name]
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
  
  def rows_count
    return @data[:Rows].to_i
  end
  
  def column(name)
    name = name.to_s
    
    begin
      return @list[name]
    rescue Wref::Recycled
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
    
    if block_given?
      return nil
    else
      return ret
    end
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
    
    if block_given?
      return nil
    else
      return ret
    end
  end
  
  def index(name)
    name = name.to_s
    
    begin
      return @indexes_list[name]
    rescue Wref::Recycled
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
  
  def create_indexes(index_arr, args = {})
    return KnjDB_mysql::Tables::Table.create_indexes(index_arr, args.merge(:table_name => self.name, :db => @db))
  end
  
  def self.create_indexes(index_arr, args = {})
    db = args[:db]
    
    if args[:return_sql]
      sql = ""
      first = true
    end
    
    index_arr.each do |index_data|
      if !args[:return_sql]
        sql = ""
      end
      
      if args[:create] or !args.key?(:create)
        sql << "CREATE"
      end
      
      if index_data.is_a?(String)
        index_data = {"name" => index_data, "columns" => [index_data]}
      end
      
      raise "No name was given." if !index_data.key?("name") or index_data["name"].strip.length <= 0
      raise "No columns was given on index: '#{index_data["name"]}'." if !index_data["columns"] or index_data["columns"].empty?
      
      if args[:return_sql]
        if first
          first = false
        else
          sql << ", "
        end
      end
      
      sql << " UNIQUE" if index_data["unique"]
      sql << " INDEX #{db.escape_col}#{db.esc_col(index_data["name"])}#{db.escape_col}"
      
      if args[:on_table] or !args.key?(:on_table)
        sql << " ON #{db.escape_table}#{db.esc_table(args[:table_name])}#{db.escape_table}"
      end
      
      sql << " ("
      
      first = true
      index_data["columns"].each do |col_name|
        sql << ", " if !first
        first = false if first
        
        sql << "#{db.escape_col}#{db.esc_col(col_name)}#{db.escape_col}"
      end
      
      sql << ")"
      
      if !args[:return_sql]
        db.query(sql)
      end
    end
    
    if args[:return_sql]
      return sql
    else
      return nil
    end
  end
  
  def rename(newname)
    oldname = self.name
    @db.query("ALTER TABLE `#{oldname}` RENAME TO `#{newname}`")
    @db.tables.list[newname] = self
    @db.tables.list.delete(oldname)
    @data[:Name] = newname
  end
  
  def truncate
    @db.query("TRUNCATE `#{self.name}`")
    return self
  end
  
  def data
    ret = {
      "name" => self.name,
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