class Knj::Datarow
  attr_reader :data, :ob, :db
  
  def self.required_data
    @required_data = [] if !@required_data
    return @required_data
  end
  
  def self.depending_data
    @depending_data = [] if !@depending_data
    return @depending_data
  end
  
  def is_knj?
    return true
  end
  
  def self.is_nullstamp?(stamp)
    return true if !stamp or stamp == "0000-00-00 00:00:00" or stamp == "0000-00-00"
    return false
  end
  
  def self.has_many(arr)
    arr.each do |val|
      if val.is_a?(Array)
        classname, colname, methodname = *val
      elsif val.is_a?(Hash)
        classname = val[:class]
        colname = val[:col]
        methodname = val[:method]
        
        if val[:depends]
          depending_data << {
            :colname => colname,
            :classname => classname
          }
        end
      else
        raise "Unknown argument: '#{val.class.name}'."
      end
      
      if val.is_a?(Hash) and val.key?(:where)
        where_args = val[:where]
      else
        where_args = nil
      end
      
      raise "No classname given." if !classname
      methodname = "#{classname.to_s.downcase}s".to_sym if !methodname
      
      define_method(methodname) do |*args, &block|
        list_args = args[0] if args and args[0]
        list_args = {} if !list_args
        list_args.merge!(where_args) if where_args
        list_args[colname.to_s] = self.id
        
        return @ob.list(classname, list_args, &block)
      end
      
      define_method("#{methodname}_count".to_sym) do |*args|
        list_args = args[0] if args and args[0]
        list_args = {} if !list_args
        list_args[colname.to_s] = self.id
        list_args["count"] = true
        
        return @ob.list(classname, list_args)
      end
      
      define_method("#{methodname}_last".to_sym) do |args|
        args = {} if !args
        return @ob.list(classname, {"orderby" => [["id", "desc"]], "limit" => 1}.merge(args))
      end
      
      self.joined_tables(
        classname => {
          :where => {
            colname.to_s => {:type => "col", :name => :id}
          }
        }
      )
    end
  end
  
  def self.has_one(arr)
    arr.each do |val|
      methodname = nil
      colname = nil
      classname = nil
      
      if val.is_a?(Symbol)
        classname = val
        methodname = val.to_s.downcase.to_sym
        colname = "#{val.to_s.downcase}_id".to_sym
      elsif val.is_a?(Array)
        classname, colname, methodname = *val
      elsif val.is_a?(Hash)
        classname, colname, methodname = val[:class], val[:col], val[:method]
        
        if val[:required]
          colname = "#{classname.to_s.downcase}_id".to_sym if !colname
          required_data << {
            :col => colname,
            :class => classname
          }
        end
      else
        raise "Unknown argument-type: '#{arr.class.name}'."
      end
      
      methodname = classname.to_s.downcase if !methodname
      colname = "#{classname.to_s.downcase}_id".to_sym if !colname
      
      define_method(methodname) do
        return @ob.get_try(self, colname, classname)
      end
      
      methodname_html = "#{methodname.to_s}_html".to_sym
      define_method(methodname_html) do |*args|
        obj = self.send(methodname)
        return @ob.events.call(:no_html, classname) if !obj
        
        raise "Class '#{classname}' does not have a 'html'-method." if !obj.respond_to?(:html)
        return obj.html(*args)
      end
      
      self.joined_tables(
        classname => {
          :where => {
            "id" => {:type => "col", :name => colname}
          }
        }
      )
    end
  end
  
  #This method initializes joins, sets methods to update translations and makes the translations automatically be deleted when the object is deleted.
  def self.has_translation(arr)
    @translations = [] if !@translations
    
    arr.each do |val|
      @translations << val
      
      val_dc = val.to_s.downcase
      table_name = "Translation_#{val_dc}".to_sym
      
      joined_tables(
        table_name => {
          :where => {
            "object_class" => self.class,
            "object_id" => {:type => "col", :name => "id"},
            "key" => val.to_s,
            "locale" => proc{|d| _session[:locale]}
          },
          :parent_table => :Translation,
          :datarow => Knj::Translations::Translation,
          :ob => @ob
        }
      )
      
      define_method("#{val_dc}=") do |newtransval|
        _kas.trans_set(self, {
          val => newtransval
        })
      end
      
      define_method("#{val_dc}") do
        return _kas.trans(self, val)
      end
      
      define_method("#{val_dc}_html") do
        str = _kas.trans(self, val)
        if str.to_s.strip.length <= 0
          return "[no translation for #{val}]"
        end
        
        return str
      end
    end
  end
  
  def self.translations
    return @translations
  end
  
  def self.joined_tables(hash)
    @columns_joined_tables = {} if !@columns_joined_tables
    @columns_joined_tables.merge!(hash)
  end
  
  def self.table
    return @table if @table
    return self.name.split("::").last
  end
  
  def self.table=(newtable)
    @table = newtable
    @columns_sqlhelper_args[:table] = @table if @columns_sqlhelper_args.is_a?(Hash)
  end
  
  def table
    return self.class.table
  end
  
  def self.columns(d)
    columns_load(d) if !@columns
    return @columns
  end
  
  def self.columns_load(d)
    return nil if @columns
    @ob = d.ob
    @columns = d.db.tables[table].columns
  end
  
  def self.columns_sqlhelper_args
    return @columns_sqlhelper_args
  end
  
  def self.list(d, &block)
    ec_col = d.db.enc_col
    ec_table = d.db.enc_table
    
    table_str = "#{ec_table}#{d.db.esc_table(self.table)}#{ec_table}"
    
    if d.args["count"]
      count = true
      d.args.delete("count")
      sql = "SELECT COUNT(#{table_str}.#{ec_col}id#{ec_col}) AS count"
    elsif d.args["select_col_as_array"]
      select_col_as_array = true
      sql = "SELECT #{table_str}.#{ec_col}#{d.args["select_col_as_array"]}#{ec_col} AS id"
      d.args.delete("select_col_as_array")
    else
      sql = "SELECT #{table_str}.*"
    end
    
    ret = self.list_helper(d)
    
    sql << " FROM #{table_str}"
    sql << ret[:sql_joins]
    sql << " WHERE 1=1"
    sql << ret[:sql_where]
    
    d.args.each do |key, val|
      case key
        when "return_sql"
          #ignore
        else
          raise "Invalid key: '#{key}' for '#{self.name}'."
      end
    end
    
    #The count will bug if there is a group-by-statement.
    grp_shown = false
    if !count and !ret[:sql_groupby]
      sql << " GROUP BY #{table_str}.#{ec_col}id#{ec_col}"
      grp_shown = true
    end
    
    if ret[:sql_groupby]
      if !grp_shown
        sql << " GROUP BY"
      else
        sql << ", "
      end
      
      sql << ret[:sql_groupby]
    end
    
    sql << ret[:sql_order]
    sql << ret[:sql_limit]
    
    return sql.to_s if d.args["return_sql"]
    
    if select_col_as_array
      ids = [] if !block
      d.db.q(sql) do |data|
        if block
          block.call(data[:id])
        else
          ids << data[:id]
        end
      end
      
      if !block
        return ids
      else
        return nil
      end
    elsif count
      ret = d.db.query(sql).fetch
      return ret[:count].to_i if ret
      return 0
    end
    
    return d.ob.list_bysql(self.classname, sql, &block)
  end
  
  def self.classname
    return @classname
  end
  
  def self.classname=(newclassname)
    @classname = newclassname
  end
  
  def self.load_columns(d)
    if !@classname
      if match = self.name.match(/($|::)([A-z\d_]+?)$/)
        @classname = match[2].to_sym 
      else
        @classname = self.name.to_sym
      end
    end
    
    @mutex = Mutex.new if !@mutex
    
    @mutex.synchronize do
      cols = self.columns(d)
      inst_methods = instance_methods(false)
      
      sqlhelper_args = {
        :db => d.db,
        :table => table,
        :cols_bools => [],
        :cols_date => [],
        :cols_dbrows => [],
        :cols_num => [],
        :cols_str => [],
        :cols => {}
      }
      
      sqlhelper_args[:table] = @table if @table
      
      cols.each do |col_name, col_obj|
        col_type = col_obj.type
        col_type = "int" if col_type == "bigint" or col_type == "tinyint" or col_type == "mediumint" or col_type == "smallint"
        sqlhelper_args[:cols][col_name] = true
        
        #Spawns a method on the class which returns true if the data is 1.
        method_name = "#{col_name}?".to_sym
        
        if !inst_methods.index(method_name)
          define_method(method_name) do
            return true if self[col_name.to_sym].to_s == "1"
            return false
          end
        end
        
        if col_type == "enum" and col_obj.maxlength == "'0','1'"
          sqlhelper_args[:cols_bools] << col_name
        elsif col_type == "int" and col_name.slice(-3, 3) == "_id"
          sqlhelper_args[:cols_dbrows] << col_name
        elsif col_type == "int" or col_type == "bigint" or col_type == "decimal"
          sqlhelper_args[:cols_num] << col_name
        elsif col_type == "varchar" or col_type == "text" or col_type == "enum"
          sqlhelper_args[:cols_str] << col_name
        elsif col_type == "date" or col_type == "datetime"
          sqlhelper_args[:cols_date] << col_name
          method_name = "#{col_name}_str".to_sym
          
          if !inst_methods.index(method_name)
            define_method(method_name) do |*args|
              if Knj::Datet.is_nullstamp?(self[col_name.to_sym])
                return @ob.events.call(:no_date, self.class.name)
              end
              
              return Knj::Datet.in(self[col_name.to_sym]).out(*args)
            end
          end
          
          method_name = "#{col_name}".to_sym
          if !inst_methods.index(method_name)
            define_method(method_name) do |*args|
              return false if Knj::Datet.is_nullstamp?(self[col_name.to_sym])
              return Knj::Datet.in(self[col_name.to_sym])
            end
          end
        end
        
        if col_type == "int" or col_type == "decimal"
          method_name = "#{col_name}_format"
          if inst_methods.index(method_name) == nil
            define_method(method_name) do |*args|
              return Knj::Locales.number_out(self[col_name.to_sym], *args)
            end
          end
        end
        
        if col_type == "int" or col_type == "varchar"
          method_name = "by_#{col_name}".to_sym
          if !inst_methods.index(method_name) and RUBY_VERSION.to_s.slice(0, 3) != "1.8"
            define_singleton_method(method_name) do |arg|
              return d.ob.get_by(self.table, {col_name.to_s => arg})
            end
          end
        end
        
        if col_type == "time"
          method_name = "#{col_name}_dbt"
          if !inst_methods.index(method_name)
            define_method(method_name) do
              return Knj::Db::Dbtime.new(self[col_name.to_sym])
            end
          end
        end
      end
      
      if @columns_joined_tables
        @columns_joined_tables.each do |table_name, table_data|
          table_data[:where].each do |key, val|
            val[:table] = self.table.to_sym if val.is_a?(Hash) and !val.key?(:table) and val[:type] == "col"
          end
          
          table_data[:datarow] = @ob.args[:module].const_get(table_name.to_sym) if !table_data.key?(:datarow)
        end
        
        sqlhelper_args[:joined_tables] = @columns_joined_tables
      end
      
      @columns_sqlhelper_args = sqlhelper_args
    end
    
    self.init_class(d) if self.respond_to?(:init_class)
  end
  
  def self.list_helper(d)
    self.load_columns(d) if !@columns_sqlhelper_args
    @columns_sqlhelper_args[:table] = @table if @table
    return d.ob.sqlhelper(d.args, @columns_sqlhelper_args)
  end
  
  def initialize(d)
    @ob = d.ob
    @db = d.ob.db
    raise "No ob given." if !@ob
    
    if d.data.is_a?(Hash)
      @data = d.data
    elsif d.data
      @data = {:id => d.data}
      self.reload
    else
      raise Knj::Errors::InvalidData, "Could not figure out the data from '#{d.data.class.name}'."
    end
  end
  
  #Reloads the data from the database.
  def reload
    data = @db.single(self.table, {:id => @data[:id]})
    if !data
      raise Knj::Errors::NotFound, "Could not find any data for the object with ID: '#{@data[:id]}' in the table '#{self.table}'."
    end
    
    @data = data
  end
  
  #Writes/updates new data for the object.
  def update(newdata)
    @db.update(self.table, newdata, {:id => @data[:id]})
    self.reload
    
    if @ob
      @ob.call("object" => self, "signal" => "update")
    end
  end
  
  #Forcefully destroys the object. This is done after deleting it and should not be called manually.
  def destroy
    @ob = nil
    @db = nil
    @data = nil
  end
  
  #Alias for key?
  def has_key?(key)
    return @data.key?(key.to_sym)
  end
  
  #Returns true if that key exists on the object.
  def key?(key)
    return @data.key?(key.to_sym)
  end
  
  #Returns true if the object has been deleted.
  def deleted?
    if !@ob and !@data
      return true
    end
    
    return false
  end
  
  #Returns a specific data from the object by key.
  def [](key)
    raise "Key was not a symbol: '#{key.class.name}'." if !key.is_a?(Symbol)
    raise "No data was loaded on the object? Maybe you are trying to call a deleted object?" if !@data
    return @data[key] if @data.key?(key)
    raise "No such key: '#{key}'."
  end
  
  #Writes/updates a keys value on the object.
  def []=(key, value)
    self.update(key.to_sym => value)
    self.reload
  end
  
  #Returns the objects ID.
  def id
    raise "No data on object." if !@data
    return @data[:id]
  end
  
  #Tries to figure out, and returns, the possible name or title for the object.
  def name
    if @data.key?(:title)
      return @data[:title]
    elsif @data.key?(:name)
      return @data[:name]
    end
    
    obj_methods = self.class.instance_methods(false)
    [:name, :title].each do |method_name|
      return self.method(method_name).call if obj_methods.index(method_name)
    end
    
    raise "Couldnt figure out the title/name of the object on class #{self.class.name}."
  end
  
  #Calls the name-method and returns a HTML-escaped value. Also "[no name]" if the name is empty.
  def name_html
    name_str = self.name.to_s
    if name_str.length <= 0
      name_str = "[no name]"
    end
    
    return name_str
  end
  
  alias :title :name
  
  #Loops through the data on the object.
  def each(&args)
    return @data.each(&args)
  end
end