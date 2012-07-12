#This class helps create models in a framework with Knj::Db and Knj::Objects.
#===Examples
# db = Knj::Db.new(:type => "sqlite3", :path => "somepath.sqlite3")
# ob = Knj::Objects.new(:db => db, :datarow => true, :path => "path_of_model_class_files")
# user = ob.get(:User, 1) #=> <Models::User> that extends <Knj::Datarow>
class Knj::Datarow
  #Returns the data-hash that contains all the data from the database.
  def data
    self.reload if @should_reload
    return @data
  end
  
  #Returns the Knj::Objects which handels this model.
  attr_reader :ob
  
  #Returns the Knj::Db which handels this model.
  attr_reader :db
  
  #This is used by 'Knj::Objects' to find out what data is required for this class. Returns the array that tells about required data.
  #===Examples
  #When adding a new user, this can fail if the ':group_id' is not given, or the ':group_id' doesnt refer to a valid group-row in the db.
  # class Models::User < Knj::Datarow
  #   has_one [
  #     {:class => :Group, :col => :group_id, :method => :group, :required => true}
  #   ]
  # end
  def self.required_data
    @required_data = [] if !@required_data
    return @required_data
  end
  
  #This is used by 'Knj::Objects' to find out what other objects this class depends on. Returns the array that tells about depending data.
  #===Examples
  #This will tell Knj::Objects that files depends on users. It can prevent the user from being deleted, if any files depend on it.
  # class Models::User < Knj::Datarow
  #   has_many [
  #     {:class => :File, :col => :user_id, :method => :files, :depends => true}
  #   ]
  # end
  def self.depending_data
    @depending_data = [] if !@depending_data
    return @depending_data
  end
  
  #Returns true if this class has been initialized.
  def self.initialized?
    return false if !@ob or !@columns_sqlhelper_args
    return true
  end
  
  #This is used by 'Knj::Objects' to find out which other objects should be deleted when an object of this class is deleted automatically. Returns the array that tells about autodelete data.
  #===Examples
  #This will trigger Knj::Objects to automatically delete all the users pictures, when deleting the current user.
  # class Models::User < Knj::Datarow
  #   has_many [
  #     {:class => :Picture, :col => :user_id, :method => :pictures, :autodelete => true}
  #   ]
  # end
  def self.autodelete_data
    @autodelete_data = [] if !@autodelete_data
    return @autodelete_data
  end
  
  #Get the 'Knj::Objects'-object that handels this class.
  def self.ob
    return @ob
  end
  
  #This helps various parts of the framework determine if this is a datarow class without requiring it.
  #===Examples
  # print "This is a knj-object." if obj.respond_to?("is_knj?")
  def is_knj?
    return true
  end
  
  #This tests if a certain string is a date-null-stamp.
  #===Examples
  # time_str = dbrow[:date]
  # print "No valid date on the row." if Knj::Datarow.is_nullstamp?(time_str)
  def self.is_nullstamp?(stamp)
    return true if !stamp or stamp == "0000-00-00 00:00:00" or stamp == "0000-00-00"
    return false
  end
  
  #This is used to define datarows that this object can have a lot of.
  #===Examples
  #This will define the method "pictures" on 'Models::User' that will return all pictures for the users and take possible Objects-sql-arguments. It will also enabling joining pictures when doing Objects-sql-lookups.
  # class Models::User < Knj::Datarow
  #   has_many [
  #     [:Picture, :user_id, :pictures],
  #     {:class => :File, :col => :user_id, :method => :files}
  #   ]
  # end
  def self.has_many(arr)
    arr.each do |val|
      if val.is_a?(Array)
        classname, colname, methodname = *val
      elsif val.is_a?(Hash)
        classname, colname, methodname = nil, nil, nil
        
        val.each do |hkey, hval|
          case hkey
            when :class
              classname = hval
            when :col
              colname = hval
            when :method
              methodname = hval
            when :depends, :autodelete, :where
              #ignore
            else
              raise "Invalid key for 'has_many': '#{hkey}'."
          end
        end
        
        colname = "#{self.name.to_s.split("::").last.to_s.downcase}_id".to_sym if colname.to_s.empty?
        
        if val[:depends]
          self.depending_data << {
            :colname => colname,
            :classname => classname
          }
        end
        
        if val[:autodelete]
          self.autodelete_data << {
            :colname => colname,
            :classname => classname
          }
        end
      else
        raise "Unknown argument: '#{val.class.name}'."
      end
      
      raise "No classname given." if !classname
      methodname = "#{classname.to_s.downcase}s".to_sym if !methodname
      raise "No column was given for '#{self.name}' regarding has-many-class: '#{classname}'." if !colname
      
      if val.is_a?(Hash) and val.key?(:where)
        where_args = val[:where]
      else
        where_args = nil
      end
      
      define_method(methodname) do |*args, &block|
        if args and args[0]
          list_args = args[0] 
        else
          list_args = {}
        end
        
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
            colname.to_s => {:type => :col, :name => :id}
          }
        }
      )
    end
  end
  
  #This define is this object has one element of another datarow-class. It define various methods and joins based on that.
  #===Examples
  # class Models::User < Knj::Datarow
  #   has_one [
  #     #Defines the method 'group', which returns a 'Group'-object by the column 'group_id'.
  #     :Group,
  #     
  #     #Defines the method 'type', which returns a 'Type'-object by the column 'type_id'.
  #     {:class => :Type, :col => :type_id, :method => :type}
  #   ]
  # end
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
        classname, colname, methodname = nil, nil, nil
        
        val.each do |hkey, hval|
          case hkey
            when :class
              classname = hval
            when :col
              colname = hval
            when :method
              methodname = hval
            when :required
              #ignore
            else
              raise "Invalid key for class '#{self.name}' functionality 'has_many': '#{hkey}'."
          end
        end
        
        if val[:required]
          colname = "#{classname.to_s.downcase}_id".to_sym if !colname
          self.required_data << {
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
      
      methodname_html = "#{methodname}_html".to_sym
      define_method(methodname_html) do |*args|
        obj = self.__send__(methodname)
        return @ob.events.call(:no_html, classname) if !obj
        
        raise "Class '#{classname}' does not have a 'html'-method." if !obj.respond_to?(:html)
        return obj.html(*args)
      end
      
      methodname_name = "#{methodname}_name".to_sym
      define_method(methodname_name) do |*args|
        obj = self.__send__(methodname)
        return @ob.events.call(:no_name, classname) if !obj
        return obj.name(*args)
      end
      
      self.joined_tables(
        classname => {
          :where => {
            "id" => {:type => :col, :name => colname}
          }
        }
      )
    end
  end
  
  #This method initializes joins, sets methods to update translations and makes the translations automatically be deleted when the object is deleted.
  #===Examples
  # class Models::Article < Knj::Datarow
  #   #Defines methods such as: 'title', 'title=', 'content', 'content='. When used with Knjappserver these methods will change what they return and set based on the current language of the session.
  #   has_translation [:title, :content]
  # end
  #
  # article = ob.get(:Article, 1)
  # print "The title in the current language is: '#{article.title}'."
  #
  # article.title = 'Title in english if the language is english'
  def self.has_translation(arr)
    @translations = [] if !@translations
    
    arr.each do |val|
      @translations << val
      
      val_dc = val.to_s.downcase
      table_name = "Translation_#{val_dc}".to_sym
      
      joined_tables(
        table_name => {
          :where => {
            "object_class" => self.name,
            "object_id" => {:type => :col, :name => :id},
            "key" => val.to_s,
            "locale" => proc{|d| _session[:locale]}
          },
          :parent_table => :Translation,
          :datarow => Knj::Translations::Translation,
          :ob => @ob
        }
      )
      
      self.define_translation_methods(:val => val, :val_dc => val_dc)
    end
  end
  
  #This returns all translations for this datarow-class.
  def self.translations
    return @translations
  end
  
  #Returns data about joined tables for this class.
  def self.joined_tables(hash)
    @columns_joined_tables = {} if !@columns_joined_tables
    @columns_joined_tables.merge!(hash)
  end
  
  #Returns the table-name that should be used for this datarow.
  #===Examples
  # db.query("SELECT * FROM `#{Models::User.table}` WHERE username = 'John Doe'") do |data|
  #   print data[:id]
  # end
  def self.table
    return @table if @table
    return self.name.split("::").last
  end
  
  #This can be used to manually set the table-name. Useful when meta-programming classes that extends the datarow-class.
  #===Examples
  # Models::User.table = "prefix_User"
  def self.table=(newtable)
    @table = newtable
    @columns_sqlhelper_args[:table] = @table if @columns_sqlhelper_args.is_a?(Hash)
  end
  
  #Returns the class-name but without having to call the class-table-method. To make code look shorter.
  #===Examples
  # user = ob.get_by(:User, {:username => 'John Doe'})
  # db.query("SELECT * FROM `#{user.table}` WHERE username = 'John Doe'") do |data|
  #   print data[:id]
  # end
  def table
    return self.class.table
  end
  
  #Returns various data for the objects-sql-helper. This can be used to view various informations about the columns and more.
  def self.columns_sqlhelper_args
    raise "No SQLHelper arguments has been spawned yet." if !@columns_sqlhelper_args
    return @columns_sqlhelper_args
  end
  
  #Called by Knj::Objects to initialize the model and load column-data on-the-fly.
  def self.load_columns(d)
    @ob = d.ob if !@ob
    
    @classname = self.name.split("::").last if !@classname
    @mutex = Monitor.new if !@mutex
    
    @mutex.synchronize do
      inst_methods = self.instance_methods(false)
      
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
      
      d.db.tables[table].columns do |col_obj|
        col_name = col_obj.name
        col_type = col_obj.type
        col_type = :int if col_type == :bigint or col_type == :tinyint or col_type == :mediumint or col_type == :smallint
        sqlhelper_args[:cols][col_name] = true
        
        self.define_bool_methods(:inst_methods => inst_methods, :col_name => col_name)
        
        if col_type == :enum and col_obj.maxlength == "'0','1'"
          sqlhelper_args[:cols_bools] << col_name
        elsif col_type == :int and col_name.slice(-3, 3) == "_id"
          sqlhelper_args[:cols_dbrows] << col_name
        elsif col_type == :int or col_type == :decimal
          sqlhelper_args[:cols_num] << col_name
        elsif col_type == :varchar or col_type == :text or col_type == :enum
          sqlhelper_args[:cols_str] << col_name
        elsif col_type == :date or col_type == :datetime
          sqlhelper_args[:cols_date] << col_name
          self.define_date_methods(:inst_methods => inst_methods, :col_name => col_name)
        end
        
        if col_type == :int or col_type == :decimal
          self.define_numeric_methods(:inst_methods => inst_methods, :col_name => col_name)
        end
        
        if col_type == :int or col_type == :varchar
          self.define_text_methods(:inst_methods => inst_methods, :col_name => col_name)
        end
        
        if col_type == :time
          self.define_time_methods(:inst_methods => inst_methods, :col_name => col_name)
        end
      end
      
      if @columns_joined_tables
        @columns_joined_tables.each do |table_name, table_data|
          table_data[:where].each do |key, val|
            val[:table] = self.table.to_sym if val.is_a?(Hash) and !val.key?(:table) and val[:type].to_sym == :col
          end
          
          table_data[:datarow] = @ob.args[:module].const_get(table_name.to_sym) if !table_data.key?(:datarow)
        end
        
        sqlhelper_args[:joined_tables] = @columns_joined_tables
      end
      
      @columns_sqlhelper_args = sqlhelper_args
    end
    
    self.init_class(d) if self.respond_to?(:init_class)
  end
  
  #This method helps returning objects and supports various arguments. It should be called by Object#list.
  #===Examples
  # ob.list(:User, {"username_lower" => "john doe"}) do |user|
  #   print user.id
  # end
  #
  # array = ob.list(:User, {"id" => 1})
  # print array.length
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
    
    qargs = nil
    ret = self.list_helper(d)
    
    sql << " FROM #{table_str}"
    sql << ret[:sql_joins]
    sql << " WHERE 1=1"
    sql << ret[:sql_where]
    
    d.args.each do |key, val|
      case key
        when "return_sql"
          #ignore
        when :cloned_ubuf
          qargs = {:cloned_ubuf => true}
        else
          raise "Invalid key: '#{key}' for '#{self.name}'. Valid keys are: '#{@columns_sqlhelper_args[:cols].keys.sort}'. Date-keys: '#{@columns_sqlhelper_args[:cols_date]}'."
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
      enum = Enumerator.new do |yielder|
        d.db.q(sql, qargs) do |data|
          yielder << data[:id]
        end
      end
      
      if block
        enum.each(&block)
        return nil
      elsif d.ob.args[:array_enum]
        return Array_enumerator.new(enum)
      else
        return enum.to_a
      end
    elsif count
      ret = d.db.query(sql).fetch
      return ret[:count].to_i if ret
      return 0
    end
    
    return d.ob.list_bysql(self.classname, sql, qargs, &block)
  end
  
  #Helps call 'sqlhelper' on Knj::Objects to generate SQL-strings.
  def self.list_helper(d)
    self.load_columns(d) if !@columns_sqlhelper_args
    @columns_sqlhelper_args[:table] = @table if @table
    return d.ob.sqlhelper(d.args, @columns_sqlhelper_args)
  end
  
  #Returns the classname of the object without any subclasses.
  def self.classname
    return @classname
  end
  
  #Sets the classname to something specific in order to hack the behaviour.
  def self.classname=(newclassname)
    @classname = newclassname
  end
  
  #Initializes the object. This should be called from 'Knj::Objects' and not manually.
  #===Examples
  # user = ob.get(:User, 3)
  def initialize(data, args = nil)
    @ob = self.class.ob
    raise "No ob given." if !@ob
    @db = ob.db
    
    if data.is_a?(Hash) and data.key?(:id)
      @data = data
      @id = @data[:id].to_i
    elsif data
      @id = data.to_i
      
      classname = self.class.classname.to_sym
      if @ob.ids_cache_should.key?(classname)
        #ID caching is enabled for this model - dont reload until first use.
        raise Knj::Errors::NotFound, "ID was not found in cache: '#{id}'." if !@ob.ids_cache[classname].key?(@id)
        @should_reload = true
      else
        #ID caching is not enabled - reload now to check if row exists. Else set 'should_reload'-variable if 'skip_reload' is set.
        if !args or !args[:skip_reload]
          self.reload
        else
          @should_reload = true
        end
      end
    else
      raise Knj::Errors::InvalidData, "Could not figure out the data from '#{data.class.name}'."
    end
    
    if @id.to_i <= 0
      raise "Invalid ID: '#{@id}' from '#{@data}'."if @data
      raise "Invalid ID: '#{@id}'."
    end
  end
  
  #Reloads the data from the database.
  #===Examples
  # old_username = user[:username]
  # user.reload
  # print "The username changed in the database!" if user[:username] != old_username
  def reload
    @data = @db.single(self.table, {:id => @id})
    raise Knj::Errors::NotFound, "Could not find any data for the object with ID: '#{@id}' in the table '#{self.table}'." if !@data
    @should_reload = false
  end
  
  #Tells the object that it should reloads its data because it has changed. It wont reload before it is required though, which may save you a couple of SQL-calls.
  #===Examples
  # obj = _ob.get(:User, 5)
  # obj.should_reload
  def should_reload
    @should_reload = true
    @data = nil
  end
  
  #Writes/updates new data for the object.
  #===Examples
  # user.update(:username => 'New username', :date_changed => Time.now)
  def update(newdata)
    @db.update(self.table, newdata, {:id => @id})
    self.should_reload
    @ob.call("object" => self, "signal" => "update") if @ob
  end
  
  #Forcefully destroys the object. This is done after deleting it and should not be called manually.
  def destroy
    @id = nil
    @ob = nil
    @db = nil
    @data = nil
    @should_reload = nil
  end
  
  #Returns true if that key exists on the object.
  #===Examples
  # print "Looks like the user has a name." if user.key?(:name)
  def key?(key)
    self.reload if @should_reload
    return @data.key?(key.to_sym)
  end
  alias has_key? key?
  
  #Returns true if the object has been deleted.
  #===Examples
  # print "That user is deleted." if user.deleted?
  def deleted?
    return true if !@ob and !@data and !@id
    return false
  end
  
  #Returns a specific data from the object by key.
  # print "Username: #{user[:username]}\n"
  # print "ID: #{user[:id]}\n"
  # print "ID again: #{user.id}\n"
  def [](key)
    raise "Key was not a symbol: '#{key.class.name}'." if !key.is_a?(Symbol)
    return @id if !@data and key == :id and @id
    self.reload if @should_reload
    raise "No data was loaded on the object? Maybe you are trying to call a deleted object? (#{self.class.classname}(#{@id}), #{@should_reload})" if !@data
    return @data[key] if @data.key?(key)
    raise "No such key: '#{key}' on '#{self.class.name}' (#{@data.keys.join(", ")}) (#{@should_reload})."
  end
  
  #Writes/updates a keys value on the object.
  # user = ob.get_by(:User, {"username" => "John Doe"})
  # user[:username] = 'New username'
  def []=(key, value)
    self.update(key.to_sym => value)
    self.should_reload
  end
  
  #Returns the objects ID.
  def id
    raise "This object has been deleted." if self.deleted?
    raise "No ID on object." if !@id
    return @id
  end
  
  #This enable Wref to not return the wrong object.
  def __object_unique_id__
    return 0 if self.deleted?
    return self.id
  end
  
  #Tries to figure out, and returns, the possible name or title for the object.
  def name
    self.reload if @should_reload
    
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
    name_str = "[no name]" if name_str.length <= 0
    return name_str
  end
  
  alias title name
  
  #Loops through the data on the object.
  #===Examples
  # user = ob.get(:User, 1)
  # user.each do |key, val|
  #   print "#{key}: #{val}\n" #=> username: John Doe
  # end
  def each(*args, &block)
    self.reload if @should_reload
    return @data.each(*args, &block)
  end
  
  private
  
  #Various methods to define methods based on the columns for the datarow.
  def self.define_translation_methods(args)
    define_method("#{args[:val_dc]}=") do |newtransval|
      _kas.trans_set(self, {
        args[:val] => newtransval
      })
    end
    
    define_method("#{args[:val_dc]}") do
      return _kas.trans(self, args[:val])
    end
    
    define_method("#{args[:val_dc]}_html") do
      str = _kas.trans(self, args[:val])
      if str.to_s.strip.length <= 0
        return "[no translation for #{args[:val]}]"
      end
      
      return str
    end
  end
  
  #Defines the boolean-methods based on enum-columns.
  def self.define_bool_methods(args)
    #Spawns a method on the class which returns true if the data is 1.
    method_name = "#{args[:col_name]}?".to_sym
    
    if args[:inst_methods].index(method_name) == nil
      define_method(method_name) do
        return true if self[args[:col_name].to_sym].to_s == "1"
        return false
      end
    end
  end
  
  #Defines date- and time-columns based on datetime- and date-columns.
  def self.define_date_methods(args)
    method_name = "#{args[:col_name]}_str".to_sym
    if args[:inst_methods].index(method_name) == nil
      define_method(method_name) do |*method_args|
        if Datet.is_nullstamp?(self[args[:col_name].to_sym])
          return @ob.events.call(:no_date, self.class.name)
        end
        
        return Datet.in(self[args[:col_name].to_sym]).out(*method_args)
      end
    end
    
    method_name = "#{args[:col_name]}".to_sym
    if args[:inst_methods].index(method_name) == nil
      define_method(method_name) do |*method_args|
        return false if Datet.is_nullstamp?(self[args[:col_name].to_sym])
        return Datet.in(self[args[:col_name].to_sym])
      end
    end
  end
  
  #Define various methods based on integer-columns.
  def self.define_numeric_methods(args)
    method_name = "#{args[:col_name]}_format"
    if args[:inst_methods].index(method_name) == nil
      define_method(method_name) do |*method_args|
        return Knj::Locales.number_out(self[args[:col_name].to_sym], *method_args)
      end
    end
  end
  
  #Define methods to look up objects directly.
  #===Examples
  # user = Models::User.by_username('John Doe')
  # print user.id
  def self.define_text_methods(args)
    method_name = "by_#{args[:col_name]}".to_sym
    if args[:inst_methods].index(method_name) == nil and RUBY_VERSION.to_s.slice(0, 3) != "1.8"
      define_singleton_method(method_name) do |arg|
        return d.ob.get_by(self.table, {args[:col_name].to_s => arg})
      end
    end
  end
  
  #Defines dbtime-methods based on time-columns.
  def self.define_time_methods(args)
    method_name = "#{args[:col_name]}_dbt"
    if args[:inst_methods].index(method_name) == nil
      define_method(method_name) do
        return Knj::Db::Dbtime.new(self[args[:col_name].to_sym])
      end
    end
  end
end