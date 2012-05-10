require "#{$knjpath}wref"

class KnjDB_sqlite3::Tables
  attr_reader :db, :driver
  
  def initialize(args)
    @args = args
    @db = @args[:db]
    
    @list_mutex = Mutex.new
    @list = Wref_map.new
  end
  
  def [](table_name)
    table_name = table_name.to_s
    
    begin
      return @list[table_name]
    rescue Wref::Recycled
      #ignore.
    end
    
    self.list do |table_obj|
      return table_obj if table_obj.name.to_s == table_name
    end
    
    raise Knj::Errors::NotFound.new("Table was not found: #{table_name}.")
  end
  
  def list
    ret = {} unless block_given?
    
    @list_mutex.synchronize do
      q_tables = @db.select("sqlite_master", {"type" => "table"}, {"orderby" => "name"}) do |d_tables|
        obj = @list.get!(d_tables[:name])
        
        if !obj
          obj = KnjDB_sqlite3::Tables::Table.new(
            :db => @db,
            :data => d_tables
          )
          @list[d_tables[:name]] = obj
        end
        
        if block_given?
          yield(obj)
        else
          ret[d_tables[:name]] = obj
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
    sql = "CREATE TABLE `#{name}` ("
    
    first = true
    data["columns"].each do |col_data|
      sql << ", " if !first
      first = false if first
      sql << @db.cols.data_sql(col_data)
    end
    
    sql << ")"
    
    @db.query(sql)
    
    if data.key?("indexes") and data["indexes"]
      table_obj = self[name]
      table_obj.create_indexes(data["indexes"])
    end
  end
end

class KnjDB_sqlite3::Tables::Table
  def initialize(args)
    @db = args[:db]
    @data = args[:data]
    
    @list = Wref_map.new
    @indexes_list = Wref_map.new
  end
  
  def name
    return @data[:name]
  end
  
  def drop
    sql = "DROP TABLE `#{self.name}`"
    @db.query(sql)
  end
  
  def optimize
    raise "stub!"
  end
  
  def table
    return @db.tables[@table_name]
  end
  
  def column(name)
    list = self.columns
    return list[name] if list[name]
    raise Knj::Errors::NotFound.new("Column not found: #{name}.")
  end
  
  def columns
    @db.cols
    ret = {}
    
    @db.q("PRAGMA table_info(`#{@db.esc_table(self.name)}`)") do |d_cols|
      obj = @list.get!(d_cols[:name])
      
      if !obj
        obj = KnjDB_sqlite3::Columns::Column.new(
          :table_name => self.name,
          :db => @db,
          :data => d_cols
        )
        @list[d_cols[:name]] = obj
      end
      
      if block_given?
        yield(obj)
      else
        ret[d_cols[:name]] = obj
      end
    end
    
    if block_given?
      return nil
    else
      return ret
    end
  end
  
  def create_columns(col_arr)
    col_arr.each do |col_data|
      #if col_data.key?("after")
      #  self.create_column_programmatic(col_data)
      #else
        @db.query("ALTER TABLE `#{self.name}` ADD COLUMN #{@db.cols.data_sql(col_data)};")
      #end
    end
  end
  
  def create_column_programmatic(col_data)
    temp_name = "temptable_#{Time.now.to_f.to_s.hash}"
    cloned_tabled = self.clone(temp_name)
    cols_cur = self.columns
    @db.query("DROP TABLE `#{self.name}`")
    
    sql = "CREATE TABLE `#{self.name}` ("
    first = true
    cols_cur.each do |name, col|
      sql << ", " if !first
      first = false if first
      sql << @db.cols.data_sql(col.data)
      
      if col_data["after"] and col_data["after"] == name
        sql << ", #{@db.cols.data_sql(col_data)}"
      end
    end
    sql << ");"
    @db.query(sql)
    
    sql = "INSERT INTO `#{self.name}` SELECT "
    first = true
    cols_cur.each do |name, col|
      sql << ", " if !first
      first = false if first
      
      sql << "`#{name}`"
      
      if col_data["after"] and col_data["after"] == name
        sql << ", ''"
      end
    end
    sql << " FROM `#{temp_name}`"
    @db.query(sql)
    @db.query("DROP TABLE `#{temp_name}`")
  end
  
  def clone(newname)
    raise "Invalid name." if newname.to_s.strip.length <= 0
    cols_cur = self.columns
    
    sql = "CREATE TABLE `#{newname}` ("
    first = true
    cols_cur.each do |name, col|
      sql << ", " if !first
      first = false if first
      sql << @db.cols.data_sql(col.data)
    end
    
    sql << ");"
    @db.query(sql)
    
    sql = "INSERT INTO `#{newname}` SELECT * FROM `#{self.name}`"
    @db.query(sql)
    return @db.tables[newname]
  end
  
  def copy(args = {})
    temp_name = "temptable_#{Time.now.to_f.to_s.hash}"
    cloned_tabled = self.clone(temp_name)
    cols_cur = self.columns
    @db.query("DROP TABLE `#{self.name}`")
    
    sql = "CREATE TABLE `#{self.name}` ("
    first = true
    cols_cur.each do |name, col|
      next if args["drops"] and args["drops"].index(name) != nil
      
      sql << ", " if !first
      first = false if first
      
      if args.key?("alter_columns") and args["alter_columns"][name.to_s]
        sql << @db.cols.data_sql(args["alter_columns"][name.to_s])
      else
        sql << @db.cols.data_sql(col.data)
      end
      
      if args["new"]
        args["new"].each do |col_data|
          if col_data["after"] and col_data["after"] == name
            sql << ", #{@db.cols.data_sql(col_data)}"
          end
        end
      end
    end
    sql << ");"
    @db.query(sql)
    
    sql = "INSERT INTO `#{self.name}` SELECT "
    first = true
    cols_cur.each do |name, col|
      next if args["drops"] and args["drops"].index(name) != nil
      
      sql << ", " if !first
      first = false if first
      
      sql << "`#{name}`"
      
      if args["news"]
        args["news"].each do |col_data|
          if col_data["after"] and col_data["after"] == name
            sql << ", ''"
          end
        end
      end
    end
    
    sql << " FROM `#{temp_name}`"
    @db.query(sql)
    @db.query("DROP TABLE `#{temp_name}`")
  end
  
  def index(name)
    name = name.to_s
    
    begin
      return @indexes_list[name]
    rescue Wref::Recycled
      if @db.opts[:index_append_table_name]
        tryname = "#{self.name}__#{name}"
        
        begin
          return @indexes_list[tryname]
        rescue Wref::Recycled
          #ignore.
        end
      else
        #ignore
      end
    end
    
    self.indexes do |index|
      return index if index.name.to_s == name
    end
    
    raise Knj::Errors::NotFound.new("Index not found: #{name}.")
  end
  
  def indexes
    @db.indexes
    ret = {} unless block_given?
    
    @db.q("PRAGMA index_list(`#{@db.esc_table(self.name)}`)") do |d_indexes|
      next if d_indexes[:Key_name] == "PRIMARY"
      
      obj = @indexes_list.get!(d_indexes[:name])
      
      if !obj
        if @db.opts[:index_append_table_name]
          match_name = d_indexes[:name].match(/__(.+)$/)
          
          if match_name
            name = match_name[1]
          else
            name = d_indexes[:name]
          end
        else
          name = d_indexes[:name]
        end
        
        obj = KnjDB_sqlite3::Indexes::Index.new(
          :table_name => self.name,
          :db => @db,
          :data => d_indexes
        )
        obj.columns << name
        @indexes_list[d_indexes[:name]] = obj
      end
      
      if block_given?
        yield(obj)
      else
        ret[d_indexes[:name]] = obj
      end
    end
    
    if block_given?
      return nil
    else
      return ret
    end
  end
  
  def create_indexes(index_arr)
    index_arr.each do |index_data|
      raise "No name was given." if !index_data.key?("name") or index_data["name"].strip.length <= 0
      raise "No columns was given on index #{index_data["name"]}." if index_data["columns"].empty?
      
      name = index_data["name"]
      name = "#{self.name}__#{name}" if @db.opts[:index_append_table_name]
      
      sql = "CREATE INDEX #{@db.escape_col}#{@db.esc_col(name)}#{@db.escape_col} ON #{@db.escape_table}#{@db.esc_table(self.name)}#{@db.escape_table} ("
      
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