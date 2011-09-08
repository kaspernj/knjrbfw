class Knj::Datarow
	attr_reader :data, :ob
	
	def self.required_data
    @required_data = [] if !@required_data
    return @required_data
  end
  
  def self.depending_data
    @depending_data = [] if !@depending_data
    return @depending_data
  end
	
	def is_knj?; return true; end
	
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
      
      methodname = "#{classname.to_s.downcase}s".to_sym if !methodname
      
      define_method(methodname) do |*args|
        merge_args = args[0] if args and args[0]
        merge_args = {} if !merge_args
        return ob.list(classname, {colname.to_s => self.id}.merge(merge_args))
      end
      
      define_method("#{methodname}_count".to_sym) do |*args|
        merge_args = args[0] if args and args[0]
        merge_args = {} if !merge_args
        return ob.list(classname, {"count" => true, colname.to_s => self.id}.merge(merge_args))
      end
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
        return ob.get_try(self, colname, classname)
      end
      
      methodname_html = "#{methodname.to_s}_html".to_sym
      define_method(methodname_html) do |*args|
        obj = self.send(methodname)
        return ob.events.call(:no_html, classname) if !obj
        
        raise "Class '#{classname}' does not have a 'html'-method." if !obj.respond_to?(:html)
        return obj.html(*args)
      end
    end
	end
	
	def self.table
		return self.name.split("::").last
	end
	
	def self.columns(d)
		columns_load(d) if !@columns
		return @columns
	end
	
	def self.columns_load(d)
		return nil if @columns
		@columns = d.db.tables[table].columns
	end
	
	def self.columns_sqlhelper_args
		return @columns_sqlhelper_args
	end
	
	def self.list(d)
    if d.args["count"]
      count = true
      d.args.delete("count")
      sql = "SELECT COUNT(*) AS count"
    else
      sql = "SELECT *"
    end
    
    sql += " FROM #{d.db.enc_table}#{table}#{d.db.enc_table} WHERE 1=1"
    
    ret = list_helper(d)
    d.args.each do |key, val|
      case key
        when "return_sql"
          #ignore
        else
          raise "Invalid key: '#{key}'."
      end
    end
    
    sql += ret[:sql_where]
    sql += ret[:sql_order]
    sql += ret[:sql_limit]
    
    return sql if d.args["return_sql"]
    return d.db.query(sql).fetch[:count].to_i if count
    return d.ob.list_bysql(table, sql)
	end
	
	def self.load_columns(d)
    if @columns_sqlhelper_args_working
      sleep 0.1 while @columns_sqlhelper_args_working
      return false
    end
    
    begin
      @columns_sqlhelper_args_working = true
      cols = self.columns(d)
      
      inst_methods = instance_methods(false)
      
      sqlhelper_args = {
        :db => d.db,
        :table => table,
        :cols_bools => [],
        :cols_date => [],
        :cols_dbrows => [],
        :cols_num => [],
        :cols_str => []
      }
      cols.each do |col_name, col_obj|
        col_type = col_obj.type
        col_type = "int" if col_type == "bigint" or col_type == "tinyint" or col_type == "mediumint" or col_type == "smallint"
        
        if col_type == "enum" and col_obj.maxlength == "'0','1'"
          sqlhelper_args[:cols_bools] << col_name
          method_name = "#{col_name}?".to_sym
          
          if !inst_methods.index(method_name)
            define_method(method_name) do
              return true if self[col_name.to_sym].to_s == "1"
              return false
            end
          end
        elsif col_type == "int" and col_name.slice(-3, 3) == "_id"
          sqlhelper_args[:cols_dbrows] << col_name
        elsif col_type == "int" or col_type == "bigint"
          sqlhelper_args[:cols_num] << col_name
        elsif col_type == "varchar" or col_type == "text" or col_type == "enum"
          sqlhelper_args[:cols_str] << col_name
        elsif col_type == "date" or col_type == "datetime"
          sqlhelper_args[:cols_date] << col_name
          method_name = "#{col_name}_str".to_sym
          
          if !inst_methods.index(method_name)
            define_method(method_name) do |*args|
              if Knj::Datet.is_nullstamp?(self[col_name.to_sym])
                return ob.events.call(:no_date, self.class.name)
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
        
        if col_type == "int" or col_type == "varchar"
          method_name = "by_#{col_name}".to_sym
          if !inst_methods.index(method_name)
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
      
      @columns_sqlhelper_args = sqlhelper_args
    ensure
      @columns_sqlhelper_args_working = false
    end
    
    self.init_class(d) if self.respond_to?(:init_class)
	end
	
	def self.list_helper(d)
		load_columns(d) if !@columns_sqlhelper_args
		return d.ob.sqlhelper(d.args, @columns_sqlhelper_args)
	end
	
	def table
		return self.class.name.split("::").last
	end
	
	def initialize(d)
		@ob = d.ob
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
	
	def db
		return @ob.db
	end
	
	def reload
		data = self.db.single(self.table, {:id => @data[:id]})
		if !data
			raise Knj::Errors::NotFound, "Could not find any data for the object with ID: '#{@data[:id]}' in the table '#{self.table}'."
		end
		
		@data = data
	end
	
	def update(newdata)
		self.db.update(self.table, newdata, {:id => @data[:id]})
		self.reload
		
		if self.ob
			self.ob.call("object" => self, "signal" => "update")
		end
	end
	
	def destroy
		@ob = nil
		@data = nil
	end
	
	def has_key?(key)
		return @data.has_key?(key.to_sym)
	end
	
	def [](key)
		raise "No valid key given." if !key.is_a?(Symbol)
		raise "No data was loaded on the object? Maybe you are trying to call a deleted object?" if !@data
		return @data[key] if @data.has_key?(key)
		raise "No such key: #{key}."
	end
	
	def []=(key, value)
		self.update(key.to_sym => value)
		self.reload
	end
	
	def id
    raise "No data on object." if !@data
		return @data[:id]
	end
	
	def name
		if @data.has_key?(:title)
			return @data[:title]
		elsif @data.has_key?(:name)
			return @data[:name]
		end
		
		obj_methods = self.class.instance_methods(false)
		[:name, :title].each do |method_name|
			return self.method(method_name).call if obj_methods.index(method_name)
		end
		
		raise "Couldnt figure out the title/name of the object on class #{self.class.name}."
	end
	
	alias :title :name
	
	def each(&args)
		return @data.each(&args)
	end
end