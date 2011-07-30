class Knj::Objects
	attr_reader :args, :events
	
	def initialize(args)
		@callbacks = {}
		@args = Knj::ArrayExt.hash_sym(args)
		@args[:col_id] = :id if !@args[:col_id]
		@args[:class_pre] = "class_" if !@args[:class_pre]
		@args[:module] = Kernel if !@args[:module]
		@objects = {}
		
		@events = Knj::Event_handler.new
		@events.add_event(
      :name => :no_html,
      :connections_max => 1
		)
		
		raise "No DB given." if !@args[:db]
		raise "No class path given." if !@args[:class_path] and (@args[:require] or !@args.has_key?(:require))
	end
	
	def init_class(classname)
    return false if @objects.has_key?(classname)
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
		raise "No signals given." if !args.has_key?("signal") and !args.has_key?("signals")
		args["block"] = block if block_given?
		@callbacks[args["object"]] = {} if !@callbacks[args["object"]]
		conn_id = @callbacks[args["object"]].length.to_s
		@callbacks[args["object"]][conn_id] = args
	end
	
	def call(args, &block)
		classstr = args["object"].class.to_s
		
		if @callbacks[classstr]
			@callbacks[classstr].clone.each do |callback_key, callback|
				docall = false
				
				if callback.has_key?("signal") and args.has_key?("signal") and callback["signal"] == args["signal"]
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
	
	def requireclass(classname)
    classname = classname.to_sym
    
    if !@args[:require] and @args.has_key?(:require)
      @objects[classname] = {} if !@objects.has_key?(classname)
      return nil
    end
    
		if !@objects.has_key?(classname)
			filename = @args[:class_path] + "/#{@args[:class_pre]}#{classname.downcase}.rb"
			filename_req = @args[:class_path] + "/#{@args[:class_pre]}#{classname.downcase}"
			raise "Class file could not be found: #{filename}." if !File.exists?(filename)
			require filename_req
			@args[:module].const_get(classname).load_columns(Knj::Hash_methods.new(:args => args, :ob => self, :db => @args[:db]))
			@objects[classname] = {}
		end
	end
	
	def get(classname, data)
		classname = classname.to_sym
		
		if data.is_a?(Hash) and data[@args[:col_id].to_sym]
			id = data[@args[:col_id].to_sym].to_i
		elsif data.is_a?(Hash) and data[@args[:col_id].to_s]
			id = data[@args[:col_id].to_s].to_i
		elsif data.is_a?(Integer) or data.is_a?(String) or data.is_a?(Fixnum)
			id = data.to_i
		elsif
			raise Knj::Errors::InvalidData, "Unknown data: '#{data.class.to_s}'."
		end
		
    return @objects[classname][id] if @objects.has_key?(classname) and @objects[classname].has_key?(id)
    self.requireclass(classname) if !@objects.has_key?(classname)
    
    if @args[:datarow]
      @objects[classname][id] = @args[:module].const_get(classname).new(Knj::Hash_methods.new(
        :ob => self,
        :data => data
      ))
    else
      args = [data]
      args = args | @args[:extra_args] if @args[:extra_args]
      @objects[classname][id] = @args[:module].const_get(classname).new(*args)
    end
    
    return @objects[classname][id]
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
		return false if !id_data
		
		begin
			return self.get(obj_name, id_data)
		rescue Knj::Errors::NotFound
			return false
		end
	end
	
	def list(classname, args = {}, &block)
		classname = classname.to_sym
		self.requireclass(classname)
		classob = @args[:module].const_get(classname)
		
		raise "list-function has not been implemented for #{classname}" if !classob.respond_to?("list")
		
		if @args[:datarow]
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
		else
			return ret
		end
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
					
					if obj_data.has_key?(:name)
						objhtml = obj_data[:name]
					elsif obj_data.has_key?(:title)
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
			list[object.id] = object.title
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
		
		args = [data]
		args = args | @args[:extra_args] if @args[:extra_args]
		
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
        if !data.has_key?(req_data[:col])
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
		else
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
		raise "Only available with datarow enabled." if !@args[:datarow]
		class_name = class_name.to_sym
		method_name = method_name.to_sym
		
		self.requireclass(class_name)
		class_obj = @args[:module].const_get(class_name)
		raise "The class '#{class_obj.name}' has no such method: '#{method_name}'." if !class_obj.respond_to?(method_name)
		method_obj = class_obj.method(method_name)
		
		pass_args = []
		pass_args << Knj::Hash_methods.new(
			:ob => self,
			:db => self.db
		)
		
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
		
		#if !@objects.has_key?(classname)
			#raise "Could not find object class in cache: #{classname}."
		#elsif !@objects[classname].has_key?(object.id.to_i)
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
		
		return false if !@objects.has_key?(classname)
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
		if classn.is_a?(Array)
			classn.each do |realclassn|
				self.clean(realclassn)
			end
		else
			return false if !@objects.has_key?(classn)
      @objects[classn] = {}
      GC.start
		end
	end
	
	def clean_all
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
    @objects.keys.each do |classn|
      data = @objects[classn]
      classobj = Kernel.const_get(classn)
      ObjectSpace.each_object(classobj) do |obj|
        data[obj.id] = obj
      end
    end
	end
	
	def sqlhelper(list_args, args)
		if args[:db]
			db = args[:db]
		else
			db = @args[:db]
		end
		
		if args[:table]
			table = "`#{db.esc_table(args[:table])}`."
		else
			table = ""
		end
		
		sql_where = ""
		sql_order = ""
		sql_limit = ""
		
		limit_from = nil
		limit_to = nil
		
		cols_str_has = args.has_key?(:cols_str)
		cols_num_has = args.has_key?(:cols_num)
		cols_date_has = args.has_key?(:cols_date)
		cols_dbrows_has = args.has_key?(:cols_dbrows)
		cols_bools_has = args.has_key?(:cols_bools)
		
		if list_args.has_key?("orderby")
			orders = []
			orderstr = list_args["orderby"]
			
			if list_args["orderby"].is_a?(String)
				found = false
				found = true if !found and cols_str_has and args[:cols_str].index(orderstr) != nil
				found = true if !found and cols_date_has and args[:cols_date].index(orderstr) != nil
				found = true if !found and cols_num_has and args[:cols_num].index(orderstr) != nil
				
				if found
					sql_order += " ORDER BY "
					ordermode = " ASC"
					if list_args.has_key?("ordermode")
						if list_args["ordermode"] == "desc"
							ordermode = " DESC"
						elsif list_args["ordermode"] == "asc"
							ordermode = " ASC"
							raise "Unknown ordermode: #{list_args["ordermode"]}"
						end
						
						list_args.delete("ordermode")
					end
					
					sql_order += "#{table}`#{db.esc_col(list_args["orderby"])}`#{ordermode}"
					list_args.delete("orderby")
				end
			elsif list_args["orderby"].is_a?(Array)
				sql_order += " ORDER BY "
				
				list_args["orderby"].each do |val|
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
					else
						raise "Unknown object: #{val.class.name}"
					end
					
					found = false
					found = true if !found and cols_str_has and args[:cols_str].index(orderstr) != nil
					found = true if !found and cols_date_has and args[:cols_date].index(orderstr) != nil
					found = true if !found and cols_num_has and args[:cols_num].index(orderstr) != nil
					found = true if !found and cols_bools_has and args[:cols_bools].index(orderstr) != nil
					
					raise "Column not found for ordering: #{orderstr}." if !found
					orders << "#{table}`#{db.esc_col(orderstr)}`#{ordermode}"
				end
				
				sql_order += orders.join(", ")
				list_args.delete("orderby")
			else
				raise "Unknown orderby object: #{list_args["orderby"].class.name}."
			end
		end
		
		list_args.each do |key, val|
			found = false
			
			if (cols_str_has and args[:cols_str].index(key) != nil) or (cols_num_has and args[:cols_num].index(key) != nil) or (cols_dbrows_has and args[:cols_dbrows].index(key) != nil)
        if val.is_a?(Array)
          escape_sql = Knj::ArrayExt.join(
            :arr => val,
            :callback => proc{|value|
              db.escape(value)
            },
            :sep => ",",
            :surr => "'")
          sql_where += " AND #{table}`#{db.esc_col(key)}` IN (#{escape_sql})"
        else
          sql_where += " AND #{table}`#{db.esc_col(key)}` = '#{db.esc(val)}'"
        end
        
				found = true
			elsif cols_bools_has and args[:cols_bools].index(key) != nil
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
			elsif cols_dbrows_has and args[:cols_dbrows].index(key.to_s + "_id") != nil
				sql_where += " AND #{table}`#{db.esc_col(key.to_s + "_id")}` = '#{db.esc(val.id)}'"
				found = true
			elsif cols_str_has and match = key.match(/^([A-z_\d]+)_(search|has)$/) and args[:cols_str].index(match[1]) != nil
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
			elsif match = key.match(/^([A-z_\d]+)_not$/) and ((cols_str_has and args[:cols_str].index(match[1]) != nil) or (cols_num_has and args[:cols_num].index(match[1]) != nil))
				sql_where += " AND #{table}`#{db.esc_col(match[1])}` != '#{db.esc(val)}'"
				found = true
			elsif cols_date_has and match = key.match(/^(.+)_(day|month|from|to)$/) and args[:cols_date].index(match[1]) != nil
				if match[2] == "day"
					sql_where += " AND DATE_FORMAT(#{table}`#{db.esc_col(match[1])}`, '%d %m %Y') = DATE_FORMAT('#{db.esc(val.dbstr)}', '%d %m %Y')"
				elsif match[2] == "month"
					sql_where += " AND DATE_FORMAT(#{table}`#{db.esc_col(match[1])}`, '%m %Y') = DATE_FORMAT('#{db.esc(val.dbstr)}', '%m %Y')"
				elsif match[2] == "from"
					sql_where += " AND #{table}`#{db.esc_col(match[1])}` >= '#{db.esc(val.dbstr)}'"
				elsif match[2] == "to"
					sql_where += " AND #{table}`#{db.esc_col(match[1])}` <= '#{db.esc(val.dbstr)}'"
				else
					raise "Unknown date-key: #{match[2]}."
				end
				
				found = true
			elsif cols_num_has and match = key.match(/^(.+)_(from|to)$/) and args[:cols_num].index(match[1]) != nil
				if match[2] == "from"
					sql_where += " AND #{table}`#{db.esc_col(match[1])}` <= '#{db.esc(val)}'"
				elsif match[2] == "to"
					sql_where += " AND #{table}`#{db.esc_col(match[1])}` >= '#{db.esc(val)}'"
				else
					raise "Unknown method of treating cols-num-argument: #{match[2]}."
				end
				
				found = true
			end
			
			list_args.delete(key) if found
		end
		
		if limit_from and limit_to
			sql_limit = " LIMIT #{limit_from}, #{limit_to}"
		end
		
		return {
			:sql_where => sql_where,
			:sql_limit => sql_limit,
			:sql_order => sql_order
		}
	end
end