class Knj::Objects
	attr_reader :args, :events, :data
	
	def initialize(args)
    require "knj/arrayext"
    require "knj/event_handler"
    require "knj/hash_methods"
    
		@callbacks = {}
		@args = Knj::ArrayExt.hash_sym(args)
		@args[:col_id] = :id if !@args[:col_id]
		@args[:class_pre] = "class_" if !@args[:class_pre]
		@args[:module] = Kernel if !@args[:module]
		@args[:cache] = :weak if !@args.key?(:cache)
		@objects = {}
		@data = {}
		
		require "weakref" if @args[:cache] == :weak
		
		@events = Knj::Event_handler.new
		@events.add_event(
      :name => :no_html,
      :connections_max => 1
		)
		@events.add_event(
      :name => :no_date,
      :connections_max => 1
		)
		
		raise "No DB given." if !@args[:db] and !@args[:custom]
		raise "No class path given." if !@args[:class_path] and (@args[:require] or !@args.key?(:require))
		
		if args[:require_all]
      require "knj/php"
      loads = []
      
      Dir.foreach(@args[:class_path]) do |file|
        next if file == "." or file == ".." or !file.match(/\.rb$/)
        file_parsed = file
        file_parsed.gsub!(@args[:class_pre], "") if @args.key?(:class_pre)
        file_parsed.gsub!(/\.rb$/, "")
        file_parsed = Knj::Php.ucwords(file_parsed)
        
        loads << file_parsed
        self.requireclass(file_parsed, {:load => false})
      end
      
      loads.each do |load_class|
        self.load_class(load_class)
      end
		end
	end
	
	def init_class(classname)
    return false if @objects.key?(classname)
    @objects[classname] = {}
	end
	
	#Returns a cloned version of the @objects variable. Cloned because iteration on it may crash some of the other methods in Ruby 1.9+
	def objects
		objs_cloned = {}
		
    @objects.keys.each do |key|
      objs_cloned[key] = @objects[key].clone
    end
		
		return objs_cloned
	end
	
	def db
		return @args[:db]
	end
	
	def count_objects
		count = 0
    @objects.keys.each do |key|
      count += @objects[key].length
    end
		
		return count
	end
	
	def connect(args, &block)
		raise "No object given." if !args["object"]
		raise "No signals given." if !args.key?("signal") and !args.key?("signals")
		args["block"] = block if block_given?
		@callbacks[args["object"]] = {} if !@callbacks[args["object"]]
		conn_id = @callbacks[args["object"]].length.to_s
		@callbacks[args["object"]][conn_id] = args
	end
	
	def call(args, &block)
		classstr = args["object"].class.to_s
		
		if @callbacks.key?(classstr)
			@callbacks[classstr].clone.each do |callback_key, callback|
				docall = false
				
				if callback.key?("signal") and args.key?("signal") and callback["signal"] == args["signal"]
					docall = true
				elsif callback["signals"] and args["signal"] and callback["signals"].index(args["signal"]) != nil
					docall = true
				end
				
				next if !docall
				
				if callback["block"]
					callargs = []
					arity = callback["block"].arity
					if arity <= 0
						#do nothing
					elsif arity == 1
						callargs << args["object"]
					else
						raise "Unknown number of arguments: #{arity}"
					end
					
					callback["block"].call(*callargs)
				elsif callback["callback"]
					Knj::Php.call_user_func(callback["callback"], args)
				else
					raise "No valid callback given."
				end
			end
		end
	end
	
	def requireclass(classname, args = {})
    classname = classname.to_sym
    
		if !@objects.key?(classname)
      if (@args[:require] or !@args.key?(:require)) and (!args.key?(:require) or args[:require])
        filename = "#{@args[:class_path]}/#{@args[:class_pre]}#{classname.to_s.downcase}.rb"
        filename_req = "#{@args[:class_path]}/#{@args[:class_pre]}#{classname.to_s.downcase}"
        raise "Class file could not be found: #{filename}." if !File.exists?(filename)
        require filename_req
      end
      
      if args[:class]
        classob = args[:class]
      else
        classob = @args[:module].const_get(classname)
      end
			
			if (classob.respond_to?(:load_columns) or classob.respond_to?(:datarow_init)) and (!args.key?(:load) or args[:load])
        self.load_class(classname, args)
			end
			
			@objects[classname] = {}
		end
	end
	
	def load_class(classname, args = {})
    if args[:class]
      classob = args[:class]
    else
      classob = @args[:module].const_get(classname)
    end
    
    pass_arg = Knj::Hash_methods.new(:ob => self, :db => @args[:db])
    classob.load_columns(pass_arg) if classob.respond_to?(:load_columns)
    classob.datarow_init(pass_arg) if classob.respond_to?(:datarow_init)
	end
	
	def get(classname, data)
		classname = classname.to_sym
		
		if data.is_a?(Integer) or data.is_a?(String) or data.is_a?(Fixnum)
      id = data.to_i
		elsif data.is_a?(Hash) and data[@args[:col_id].to_sym]
			id = data[@args[:col_id].to_sym].to_i
		elsif data.is_a?(Hash) and data[@args[:col_id].to_s]
			id = data[@args[:col_id].to_s].to_i
		elsif
			raise Knj::Errors::InvalidData, "Unknown data: '#{data.class.to_s}'."
		end
		
		if @objects.key?(classname) and @objects[classname].key?(id)
      case @args[:cache]
        when :weak
          begin
            obj = @objects[classname][id]
            obj = obj.__getobj__ if obj.is_a?(WeakRef)
            
            #This actually happens sometimes... WTF!? - knj
            if obj.is_a?(Knj::Datarow) and obj.respond_to?(:table) and obj.respond_to?(:id) and obj.table.to_sym == classname and obj.id.to_i == id
              return obj
            else
              raise WeakRef::RefError
            end
          rescue WeakRef::RefError
            @objects[classname].delete(id)
          end
        else
          return @objects[classname][id]
      end
    end
    
    self.requireclass(classname) if !@objects.key?(classname)
    
    if @args[:datarow] or @args[:custom]
      obj = @args[:module].const_get(classname).new(Knj::Hash_methods.new(:ob => self, :data => data))
    else
      args = [data]
      args = args | @args[:extra_args] if @args[:extra_args]
      obj = @args[:module].const_get(classname).new(*args)
    end
    
    case @args[:cache]
      when :weak
        @objects[classname][id] = WeakRef.new(obj)
      else
        @objects[classname][id] = obj
    end
    
    return obj
	end
	
	def object_finalizer(id)
    classname = @objects_idclass[id]
    if classname
      @objects[classname].delete(id)
      @objects_idclass.delete(id)
    end
	end
	
	def get_by(classname, args = {})
		classname = classname.to_sym
		self.requireclass(classname)
		classob = @args[:module].const_get(classname)
		
		raise "list-function has not been implemented for #{classname}" if !classob.respond_to?("list")
		
		args[:limit_from] = 0
		args[:limit_to] = 1
		
		self.list(classname, args) do |obj|
			return obj
		end
		
		return false
	end
	
	def get_try(obj, col_name, obj_name = nil)
		if !obj_name
			if match = col_name.to_s.match(/^(.+)_id$/)
				obj_name = Knj::Php.ucwords(match[1]).to_sym
			else
				raise "Could not figure out objectname for: #{col_name}."
			end
		end
		
		id_data = obj[col_name].to_i
		return false if id_data.to_i <= 0
		
		begin
			return self.get(obj_name, id_data)
		rescue Knj::Errors::NotFound
			return false
		end
	end
	
	def list(classname, args = {})
		classname = classname.to_sym
		self.requireclass(classname)
		classob = @args[:module].const_get(classname)
		
		raise "list-function has not been implemented for #{classname}" if !classob.respond_to?("list")
		
		if @args[:datarow] or @args[:custom]
			ret = classob.list(Knj::Hash_methods.new(:args => args, :ob => self, :db => @args[:db]))
		else
			realargs = [args]
			realargs = realargs | @args[:extra_args] if @args[:extra_args]
			ret = classob.list(*realargs)
		end
		
		if block_given?
			ret.each do |obj|
				yield(obj)
			end
		end
		
    return ret
	end
	
	def list_opts(classname, args = {})
		Knj::ArrayExt.hash_sym(args)
		classname = classname.to_sym
		
		if args[:list_args]
			obs = self.list(classname, args[:list_args])
		else
			obs = self.list(classname)
		end
		
		html = ""
		
		if args[:addnew] or args[:add]
			html += "<option"
			html += " selected=\"selected\"" if !args[:selected]
			html += " value=\"\">#{_("Add new")}</option>"
		end
		
		obs.each do |object|
			html += "<option value=\"#{object.id.html}\""
			
			selected = false
			if args[:selected].is_a?(Array) and args[:selected].index(object) != nil
				selected = true
			elsif args[:selected] and args[:selected].respond_to?("is_knj?") and args[:selected].id.to_s == object.id.to_s
				selected = true
			end
			
			html += " selected=\"selected\"" if selected
			
			obj_methods = object.class.instance_methods(false)
			
			begin
				if obj_methods.index("name") != nil or obj_methods.index(:name) != nil
					objhtml = object.name.html
				elsif obj_methods.index("title") != nil or obj_methods.index(:title) != nil
					objhtml = object.title.html
				elsif object.respond_to?(:data)
					obj_data = object.data
					
					if obj_data.key?(:name)
						objhtml = obj_data[:name]
					elsif obj_data.key?(:title)
						objhtml = obj_data[:title]
					end
				else
          objhtml = ""
        end
				
				raise "Could not figure out which name-method to call?" if !objhtml
				html += ">#{objhtml}</option>"
			rescue Exception => e
				html += ">[#{object.class.name}: #{e.message}]</option>"
			end
		end
		
		return html
	end
	
	def list_optshash(classname, args = {})
		Knj::ArrayExt.hash_sym(args)
		classname = classname.to_sym
		
		if args[:list_args]
			obs = self.list(classname, args[:list_args])
		else
			obs = self.list(classname)
		end
		
		if RUBY_VERSION[0..2] == 1.8 and Knj::Php.class_exists("Dictionary")
			list = Dictionary.new
		else
			list = {}
		end
		
		if args[:addnew] or args[:add]
			list["0"] = _("Add new")
		elsif args[:choose]
			list["0"] = _("Choose") + ":"
		elsif args[:all]
			list["0"] = _("All")
		elsif args[:none]
			list["0"] = _("None")
		end
		
		obs.each do |object|
      if object.respond_to?(:name)
        list[object.id] = object.name
      elsif object.respond_to?(:title)
        list[object.id] = object.title
      else
        raise "Object of class '#{object.class.name}' doesnt support 'name' or 'title."
      end
		end
		
		return list
	end
	
	# Returns a list of a specific object by running specific SQL against the database.
	def list_bysql(classname, sql)
		classname = classname.to_sym
		
		ret = [] if !block_given?
		@args[:db].q(sql) do |d_obs|
			if block_given?
				yield(self.get(classname, d_obs))
			else
				ret << self.get(classname, d_obs)
			end
		end
		
		return ret if !block_given?
	end
	
	# Add a new object to the database and to the cache.
	def add(classname, data = {})
		classname = classname.to_sym
		self.requireclass(classname)
		
		if @args[:datarow]
      classobj = @args[:module].const_get(classname)
			if classobj.respond_to?(:add)
				classobj.add(Knj::Hash_methods.new(
					:ob => self,
					:db => self.db,
					:data => data
				))
			end
			
			required_data = classobj.required_data
			required_data.each do |req_data|
        if !data.key?(req_data[:col])
          raise "No '#{req_data[:class]}' given by the data '#{req_data[:col]}'."
        end
        
        begin
          obj = self.get(req_data[:class], data[req_data[:col]])
        rescue Knj::Errors::NotFound
          raise "The '#{req_data[:class]}' by ID '#{data[req_data[:col]]}' could not be found with the data '#{req_data[:col]}'."
        end
			end
			
			ins_id = @args[:db].insert(classname, data, {:return_id => true})
			retob = self.get(classname, ins_id)
    elsif @args[:custom]
      classobj = @args[:module].const_get(classname)
      retob = classobj.add(Knj::Hash_methods.new(
        :ob => self,
        :data => data
      ))
		else
      args = [data]
      args = args | @args[:extra_args] if @args[:extra_args]
			retob = @args[:module].const_get(classname).add(*args)
		end
		
		self.call("object" => retob, "signal" => "add")
		if retob.respond_to?(:add_after)
			retob.send(:add_after, {})
		end
		
		return retob
	end
	
	def adds(classname, datas)
		if !@args[:datarow]
			datas.each do |data|
				@args[:module].const_get(classname).add(*args)
				self.call("object" => retob, "signal" => "add")
			end
		else
			if @args[:module].const_get(classname).respond_to?(:add)
				datas.each do |data|
					@args[:module].const_get(classname).add(Knj::Hash_methods.new(
						:ob => self,
						:db => self.db,
						:data => data
					))
				end
			end
			
			db.insert_multi(classname, datas)
		end
	end
	
	def static(class_name, method_name, *args)
		raise "Only available with datarow enabled." if !@args[:datarow] and !@args[:custom]
		class_name = class_name.to_sym
		method_name = method_name.to_sym
		
		self.requireclass(class_name)
		class_obj = @args[:module].const_get(class_name)
		raise "The class '#{class_obj.name}' has no such method: '#{method_name}'." if !class_obj.respond_to?(method_name)
		method_obj = class_obj.method(method_name)
		
		pass_args = []
		
		if @args[:datarow]
      pass_args << Knj::Hash_methods.new(
        :ob => self,
        :db => self.db
      )
    else
      pass_args << Knj::Hash_methods.new(:ob => self)
    end
		
		args.each do |arg|
			pass_args << arg
		end
		
		method_obj.call(*pass_args)
	end
	
	# Unset object. Do this if you are sure, that there are no more references left. This will be done automatically when deleting it.
	def unset(object)
		if object.is_a?(Array)
			object.each do |obj|
				unset(obj)
			end
			return nil
		end
		
		classname = object.class.name
		
		if @args[:module]
			classname = classname.gsub(@args[:module].name + "::", "")
		end
		
		classname = classname.to_sym
		
		#if !@objects.key?(classname)
			#raise "Could not find object class in cache: #{classname}."
		#elsif !@objects[classname].key?(object.id.to_i)
			#errstr = ""
			#errstr += "Could not unset object from cache.\n"
			#errstr += "Class: #{object.class.name}.\n"
			#errstr += "ID: #{object.id}.\n"
			#errstr += "Could not find object ID in cache."
			#raise errstr
		#else
      @objects[classname].delete(object.id.to_i)
		#end
	end
	
	def unset_class(classname)
		if classname.is_a?(Array)
			classname.each do |classn|
				self.unset_class(classn)
			end
			
			return false
		end
		
		classname = classname.to_sym
		
		return false if !@objects.key?(classname)
    @objects[classname] = {}
	end
	
	# Delete an object. Both from the database and from the cache.
	def delete(object)
		self.call("object" => object, "signal" => "delete_before")
		self.unset(object)
		obj_id = object.id
		object.delete if object.respond_to?(:delete)
		
		if @args[:datarow]
      object.class.depending_data.each do |dep_data|
        objs = self.list(dep_data[:classname], {dep_data[:colname].to_s => object.id, "limit" => 1})
        if !objs.empty?
          raise "Cannot delete <#{object.class.name}:#{object.id}> because <#{objs[0].class.name}:#{objs[0].id}> depends on it."
        end
      end
      
			@args[:db].delete(object.table, {:id => obj_id})
		end
		
		self.call("object" => object, "signal" => "delete")
		object.destroy
	end
	
	def deletes(objs)
		if !@args[:datarow]
			objs.each do |obj|
				self.delete(obj)
			end
		else
			arr_ids = []
			ids = []
			objs.each do |obj|
				ids << obj.id
				if ids.length >= 1000
					arr_ids << ids
					ids = []
				end
				
				obj.delete if obj.respond_to?(:delete)
			end
			
			arr_ids << ids if ids.length > 0
			arr_ids.each do |ids|
				@args[:db].delete(objs[0].table, {:id => ids})
			end
		end
	end
	
	# Try to clean up objects by unsetting everything, start the garbagecollector, get all the remaining objects via ObjectSpace and set them again. Some (if not all) should be cleaned up and our cache should still be safe... dirty but works.
	def clean(classn)
    return false if @args[:cache] == :weak
    
		if classn.is_a?(Array)
			classn.each do |realclassn|
				self.clean(realclassn)
			end
		else
			return false if !@objects.key?(classn)
      @objects[classn] = {}
      GC.start
		end
	end
	
	# Erases the whole cache if not running weak-link-caching.
	def clean_all
    return false if @args[:cache] == :weak
    
		classnames = []
    @objects.keys.each do |classn|
      classnames << classn
    end
    
    classnames.each do |classn|
      @objects[classn] = {}
    end
		
		GC.start
	end
	
	def clean_recover
    return false if @args[:cache] == :weak
    return false if RUBY_ENGINE == "jruby" and !JRuby.objectspace
    
    @objects.keys.each do |classn|
      data = @objects[classn]
      classobj = @args[:module].const_get(classn)
      ObjectSpace.each_object(classobj) do |obj|
        begin
          data[obj.id.to_i] = obj
        rescue => e
          if e.message == "No data on object."
            #Object has been unset - skip it.
            next
          end
          
          raise e
        end
      end
    end
	end
	
	#This method helps build SQL from Objects-instances list-method. It should not be called directly but only through Objects.list.
	def sqlhelper(list_args, args_def)
		if args[:db]
			db = args[:db]
		else
			db = @args[:db]
		end
		
		args = args_def
		
		if args[:table]
			table_def = "`#{db.esc_table(args[:table])}`."
		else
			table_def = ""
		end
		
		sql_joins = ""
		sql_where = ""
		sql_order = ""
		sql_limit = ""
		
		do_joins = {}
		
		limit_from = nil
		limit_to = nil
		
		if list_args.key?("orderby")
			orders = []
			orderstr = list_args["orderby"]
			list_args["orderby"] = [list_args["orderby"]] if list_args["orderby"].is_a?(Hash)
			
			if list_args["orderby"].is_a?(String)
				found = false
				found = true if args[:cols].key?(orderstr)
				
				if found
					sql_order += " ORDER BY "
					ordermode = " ASC"
					if list_args.key?("ordermode")
						if list_args["ordermode"] == "desc"
							ordermode = " DESC"
						elsif list_args["ordermode"] == "asc"
							ordermode = " ASC"
							raise "Unknown ordermode: #{list_args["ordermode"]}"
						end
						
						list_args.delete("ordermode")
					end
					
					sql_order += "#{table_def}`#{db.esc_col(list_args["orderby"])}`#{ordermode}"
					list_args.delete("orderby")
				end
			elsif list_args["orderby"].is_a?(Array)
				sql_order += " ORDER BY "
				
				list_args["orderby"].each do |val|
          ordermode = nil
          orderstr = nil
          found = false
          
					if val.is_a?(Array)
						orderstr = val[0]
            
						if val[1] == "asc"
							ordermode = " ASC"
						elsif val[1] == "desc"
							ordermode = "DESC"
						end
					elsif val.is_a?(String)
						orderstr = val
						ordermode = " ASC"
          elsif val.is_a?(Hash)
            raise "No joined tables." if !args.key?(:joined_tables)
            
            if val[:mode] == "asc"
              ordermode = " ASC"
            elsif val[:mode] == "desc"
              ordermode = " DESC"
            end
            
            if args[:joined_tables]
              args[:joined_tables].each do |table_name, table_data|
                if table_name.to_s == val[:table]
                  do_joins[table_name] = true
                  orders << "`#{db.esc_table(table_name)}`.`#{db.esc_col(val[:col])}`#{ordermode}"
                  found = true
                  break
                end
              end
            end
					else
						raise "Unknown object: #{val.class.name}"
					end
					
					found = true if args[:cols].key?(orderstr)
					raise "Column not found for ordering: #{orderstr}." if !found
					orders << "#{table_def}`#{db.esc_col(orderstr)}`#{ordermode}" if orderstr
				end
				
				sql_order += orders.join(", ")
				list_args.delete("orderby")
			else
				raise "Unknown orderby object: #{list_args["orderby"].class.name}."
			end
		end
		
		list_args.each do |realkey, val|
			found = false
			
			if realkey.is_a?(Array)
        if !args[:joins_skip]
          datarow_obj = self.datarow_obj_from_args(args_def, list_args, realkey[0])
          args = datarow_obj.columns_sqlhelper_args
        else
          args = args_def
        end
        
        do_joins[realkey[0].to_sym] = true
        table = "`#{db.esc_table(realkey[0])}`."
        key = realkey[1]
      else
        table = table_def
        args = args_def
        key = realkey
      end
			
			if args[:cols].key?(key)
        if val.is_a?(Array)
          escape_sql = Knj::ArrayExt.join(
            :arr => val,
            :callback => proc{|value|
              db.escape(value)
            },
            :sep => ",",
            :surr => "'")
          sql_where += " AND #{table}`#{db.esc_col(key)}` IN (#{escape_sql})"
        elsif val.is_a?(Hash) and val[:type] == "col"
          if !val.key?(:table)
            Knj::Php.print_r(val)
            raise "No table was given for join."
          end
          
          do_joins[val[:table].to_sym] = true
          sql_where += " AND #{table}`#{db.esc_col(key)}` = `#{db.esc_table(val[:table])}`.`#{db.esc_col(val[:name])}`"
        elsif val.is_a?(Proc)
          call_args = Knj::Hash_methods.new(:ob => self, :db => db)
          sql_where += " AND #{table}`#{db.esc_col(key)}` = '#{db.esc(val.call(call_args))}'"
        else
          sql_where += " AND #{table}`#{db.esc_col(key)}` = '#{db.esc(val)}'"
        end
        
				found = true
			elsif args.key?(:cols_bools) and args[:cols_bools].index(key) != nil
				if val.is_a?(TrueClass) or (val.is_a?(Integer) and val.to_i == 1) or (val.is_a?(String) and (val == "true" or val == "1"))
					realval = "1"
				elsif val.is_a?(FalseClass) or (val.is_a?(Integer) and val.to_i == 0) or (val.is_a?(String) and (val == "false" or val == "0"))
					realval = "0"
				else
					raise "Could not make real value out of class: #{val.class.name} => #{val}."
				end
				
				sql_where += " AND #{table}`#{db.esc_col(key)}` = '#{db.esc(realval)}'"
				found = true
			elsif key.to_s == "limit_from"
				limit_from = val.to_i
				found = true
			elsif key.to_s == "limit_to"
				limit_to = val.to_i
				found = true
			elsif key.to_s == "limit"
				limit_from = 0
				limit_to = val.to_i
				found = true
			elsif args.key?(:cols_dbrows) and args[:cols_dbrows].index("#{key.to_s}_id") != nil
				sql_where += " AND #{table}`#{db.esc_col(key.to_s + "_id")}` = '#{db.esc(val.id)}'"
				found = true
			elsif args.key?(:cols_str) and match = key.match(/^([A-z_\d]+)_(search|has)$/) and args[:cols_str].index(match[1]) != nil
				if match[2] == "search"
					Knj::Strings.searchstring(val).each do |str|
						sql_where += " AND #{table}`#{db.esc_col(match[1])}` LIKE '%#{db.esc(str)}%'"
					end
				elsif match[2] == "has"
					if val
						sql_where += " AND #{table}`#{db.esc_col(match[1])}` != ''"
					else
						sql_where += " AND #{table}`#{db.esc_col(match[1])}` = ''"
					end
				end
				
				found = true
			elsif match = key.match(/^([A-z_\d]+)_(not|lower)$/) and args[:cols].key?(match[1])
        if match[2] == "not"
          sql_where += " AND #{table}`#{db.esc_col(match[1])}` != '#{db.esc(val)}'"
        elsif match[2] == "lower"
          sql_where += " AND LOWER(#{table}`#{db.esc_col(match[1])}`) = LOWER('#{db.esc(val)}')"
        else
          raise "Unknown mode: '#{match[2]}'."
        end
        
				found = true
			elsif args.key?(:cols_date) and match = key.match(/^(.+)_(day|month|from|to|below|above)$/) and args[:cols_date].index(match[1]) != nil
        val = Knj::Datet.in(val) if val.is_a?(Time)
        
				if match[2] == "day"
					sql_where += " AND DATE_FORMAT(#{table}`#{db.esc_col(match[1])}`, '%d %m %Y') = DATE_FORMAT('#{db.esc(val.dbstr)}', '%d %m %Y')"
				elsif match[2] == "month"
					sql_where += " AND DATE_FORMAT(#{table}`#{db.esc_col(match[1])}`, '%m %Y') = DATE_FORMAT('#{db.esc(val.dbstr)}', '%m %Y')"
				elsif match[2] == "from" or match[2] == "above"
					sql_where += " AND #{table}`#{db.esc_col(match[1])}` >= '#{db.esc(val.dbstr)}'"
				elsif match[2] == "to" or match[2] == "below"
					sql_where += " AND #{table}`#{db.esc_col(match[1])}` <= '#{db.esc(val.dbstr)}'"
				else
					raise "Unknown date-key: #{match[2]}."
				end
				
				found = true
			elsif args.key?(:cols_num) and match = key.match(/^(.+)_(from|to)$/) and args[:cols_num].index(match[1]) != nil
				if match[2] == "from"
					sql_where += " AND #{table}`#{db.esc_col(match[1])}` <= '#{db.esc(val)}'"
				elsif match[2] == "to"
					sql_where += " AND #{table}`#{db.esc_col(match[1])}` >= '#{db.esc(val)}'"
				else
					raise "Unknown method of treating cols-num-argument: #{match[2]}."
				end
				
				found = true
			elsif match = key.match(/^(.+)_lookup$/) and args[:cols].key?("#{match[1]}_id") and args[:cols].key?("#{match[1]}_class")
        sql_where += " AND #{table}`#{db.esc_col("#{match[1]}_class")}` = '#{db.esc(val.table)}'"
        sql_where += " AND #{table}`#{db.esc_col("#{match[1]}_id")}` = '#{db.esc(val.id)}'"
        found = true
			end
			
			list_args.delete(realkey) if found
		end
		
		args = args_def
		
		if !args[:joins_skip]
      raise "No joins defined on '#{args[:table]}' for: '#{args[:table]}'." if !do_joins.empty? and !args[:joined_tables]
      
      do_joins.each do |table_name, temp_val|
        raise "No join defined on table '#{args[:table]}' for table '#{table_name}'." if !args[:joined_tables].key?(table_name)
        table_data = args[:joined_tables][table_name]
        
        if table_data.key?(:parent_table)
          sql_joins += " LEFT JOIN `#{table_data[:parent_table]}` AS `#{table_name}` ON 1=1"
        else
          sql_joins += " LEFT JOIN `#{table_name}` ON 1=1"
        end
        
        if table_data[:ob]
          ob = table_data[:ob]
        else
          ob = self
        end
        
        class_name = args[:table].to_sym
        
        if table_data[:datarow]
          datarow = table_data[:datarow]
        else
          self.requireclass(class_name) if @objects.key?(class_name)
          datarow = @args[:module].const_get(class_name)
        end
        
        if !datarow.columns_sqlhelper_args
          ob.requireclass(datarow.table.to_sym)
          raise "No SQL-helper-args on class '#{datarow.table}' ???" if !datarow.columns_sqlhelper_args
        end
        
        newargs = datarow.columns_sqlhelper_args.clone
        newargs[:table] = table_name
        newargs[:joins_skip] = true
        
        #Clone the where-arguments and run them against another sqlhelper to sub-join.
        join_args = table_data[:where].clone
        ret = self.sqlhelper(join_args, newargs)
        sql_joins += ret[:sql_where]
        
        #If any of the join-arguments are left, then we should throw an error.
        join_args.each do |key, val|
          raise "Invalid key '#{key}' when trying to join table '#{table_name}' on table '#{args_def[:table]}'."
        end
      end
    end
		
		#If limit arguments has been given then add them.
		if limit_from and limit_to
			sql_limit = " LIMIT #{limit_from}, #{limit_to}"
		end
		
		return {
      :sql_joins => sql_joins,
			:sql_where => sql_where,
			:sql_limit => sql_limit,
			:sql_order => sql_order
		}
	end
	
	#Used by sqlhelper-method to look up datarow-classes and automatically load them if they arent loaded already.
	def datarow_obj_from_args(args, list_args, class_name)
    class_name = class_name.to_sym
    
    if !args.key?(:joined_tables)
      Knj::Php.print_r(list_args)
      Knj::Php.print_r(args)
      raise "No joined tables on '#{args[:table]}' to find datarow for: '#{class_name}'."
    end
    
    args[:joined_tables].each do |table_name, table_data|
      next if table_name.to_sym != class_name
      return table_data[:datarow] if table_data[:datarow]
      
      self.requireclass(class_name) if @objects.key?(class_name)
      return @args[:module].const_get(class_name)
    end
    
    raise "Could not figure out datarow for: '#{class_name}'."
	end
end