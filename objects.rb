class Knj::Objects
	attr_reader :objects
	
	def initialize(args)
		@callbacks = {}
		@args = Knj::ArrayExt.hash_sym(args)
		@args[:col_id] = :id if !@args[:col_id]
		@args[:class_pre] = "class_" if !@args[:class_pre]
		@args[:module] = Kernel if !@args[:module]
		@objects = {}
		
		raise "No DB given." if !@args[:db]
		raise "No class path given." if !@args[:class_path]
	end
	
	def count_objects
		count = 0
		@objects.clone.each do |key, value|
			value.each do |id, object|
				count += 1
			end
		end
		
		return count
	end
	
	def connect(args)
		raise "No object given." if !args["object"]
		raise "No signals given." if !args.has_key?("signal") and !args.has_key?("signals")
		args["block"] = block if block_given?
		@callbacks[args["object"]] = {} if !@callbacks[args["object"]]
		@callbacks[args["object"]][@callbacks[args["object"]].length.to_s] = args
	end
	
	def call(args)
		classstr = args["object"].class.to_s
		
		if @callbacks[classstr]
			@callbacks[classstr].each do |callback_key, callback|
				docall = false
				
				if callback.has_key?("signal") and args.has_key?("signal") and callback["signal"] == args["signal"]
					docall = true
				elsif callback["signals"] and args["signal"] and callback["signals"].index(args["signal"]) != nil
					docall = true
				end
				
				if docall
					if callback["block"]
						callback["block"].call
					elsif callback["callback"]
						Php.call_user_func(callback["callback"], args)
					else
						raise "No valid callback given."
					end
				end
			end
		end
	end
	
	def requireclass(classname)
		return nil if !@args[:require] and @args.has_key?(:require)
		classname = classname.to_s
		
		if !Php.class_exists(classname)
			filename = @args[:class_path] + "/#{@args[:class_pre]}#{classname.downcase}.rb"
			filename_req = @args[:class_path] + "/#{@args[:class_pre]}#{classname.downcase}"
			raise "Class file could not be found: #{filename}." if !File.exists?(filename)
			require filename_req
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
		else
			raise Errors::InvalidData.new("Unknown data: #{data.class.to_s}.")
		end
		
		@objects[classname] = {} if !@objects[classname]
		
		if !@objects[classname][id]
			self.requireclass(classname)
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
		
		realargs = [args]
		realargs = realargs | @args[:extra_args] if @args[:extra_args]
		
		classob.list(*realargs).each do |obj|
			return obj
		end
		
		return false
	end
	
	def list(classname, args = {}, &block)
		classname = classname.to_sym
		self.requireclass(classname)
		classob = @args[:module].const_get(classname)
		
		raise "list-function has not been implemented for #{classname}" if !classob.respond_to?("list")
		
		realargs = [args]
		realargs = realargs | @args[:extra_args] if @args[:extra_args]
		
		if block_given?
			objects_return = classob.list(*realargs, &block)
			if objects_return
				objects_return.each do |object|
					block.call(object)
				end
			end
		else
			return classob.list(*realargs)
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
		
		if args[:addnew]
			html += "<option"
			html += " selected=\"selected\"" if !args[:selected]
			html += " value=\"\">#{_("Add new")}</option>"
		end
		
		obs.each do |object|
			html += "<option value=\"#{object.id.html}\""
			html += " selected=\"selected\"" if args[:selected] and args[:selected][@args[:col_id]] == object.id
			begin
				html += ">#{object.title.html}</option>"
			rescue Exception => e
				html += ">[#{_("invalid title")}]</option>"
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
		
		if Php.class_exists("Dictionary")
			list = Dictionary.new
		else
			list = Hash.new
		end
		
		if args[:addnew]
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
	def list_bysql(classname, sql, &block)
		classname = classname.to_sym
		
		ret = []
		q_obs = @args[:db].query(sql)
		while d_obs = q_obs.fetch
			if block_given?
				block.call(self.get(classname, d_obs))
			else
				ret << self.get(classname, d_obs)
			end
		end
		
		return ret if !block_given?
	end
	
	# Add a new object to the database and to the cache.
	def add(classname, data)
		classname = classname.to_sym
		self.requireclass(classname)
		
		args = [data]
		args = args | @args[:extra_args] if @args[:extra_args]
		
		retob = @args[:module].const_get(classname).add(*args)
		self.call("object" => retob, "signal" => "add")
		return retob
	end
	
	# Unset object. Do this if you are sure, that there are no more references left. This will be done automatically when deleting it.
	def unset(object)
		classname = object.class.name
		
		if @args[:module]
			classname = classname.gsub(@args[:module].name + "::", "")
		end
		
		classname = classname.to_sym
		
		if !@objects.has_key?(classname)
			raise "Could not find object class in cache: #{object.class.name}."
		elsif !@objects[classname][object[@args[:col_id]].to_i]
			print "Could not unset object from cache.\n"
			print "Class: #{object.class.name}.\n"
			print "ID: #{object.id}.\n"
			
			Php.print_r(@objects[object.class.to_s])
			
			exit
			raise "Could not find object ID in cache."
		else
			@objects[classname].delete(object)
		end
	end
	
	# Delete an object. Both from the database and from the cache.
	def delete(object)
		self.call("object" => object, "signal" => "delete_before")
		self.unset(object)
		object.delete
		self.call("object" => object, "signal" => "delete")
	end
	
	# Try to clean up objects by unsetting everything, start the garbagecollector, get all the remaining objects via ObjectSpace and set them again. Some (if not all) should be cleaned up and our cache should still be safe... dirty but works.
	def clean(classn)
		if classn.is_a?(Array)
			classn.each do |realclassn|
				self.clean(realclassn)
			end
		else
			if !@objects[classn]
				return false
			else
				@objects[classn] = {}
				GC.start
			end
		end
	end
	
	def clean_all
		classnames = []
		@objects.clone.each do |classn, hash_list|
			classnames << classn
		end
		
		classnames.each do |classn|
			@objects[classn] = {}
		end
		
		GC.start
	end
	
	def clean_recover
		@objects.clone.each do |classn, hash_list|
			classobj = Kernel.const_get(classn)
			ObjectSpace.each_object(classobj) do |obj|
				@objects[classn][obj.id] = obj
			end
		end
	end
	
	def sqlhelper(list_args, args)
		sql_where = ""
		
		if args[:table]
			table = "`#{@args[:db].esc_table(args[:table])}`."
		else
			table = ""
		end
		
		limit_from = nil
		limit_to = nil
		
		list_args.each do |key, val|
			found = false
			if args.has_key?(:cols_str) and args[:cols_str].index(key) != nil
				sql_where += " AND #{table}`#{@args[:db].esc_col(key)}` = '#{@args[:db].esc(val)}'"
				found = true
			elsif args.has_key?(:cols_bools) and args[:cols_bools].index(key) != nil
				if val.is_a?(TrueClass) or (val.is_a?(Integer) and val.to_i == 1)
					realval = "1"
				elsif val.is_a?(FalseClass) or (val.is_a?(Integer) and val.to_i == 0)
					realval = "0"
				else
					raise "Could not make real value out of class: #{val.class.name}."
				end
				
				sql_where += " AND #{table}`#{@args[:db].esc_col(key)}` = '#{@args[:db].esc(realval)}'"
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
			elsif args.has_key?(:cols_dbrows) and args[:cols_dbrows].index(key.to_s + "_id") != nil
				sql_where += " AND #{table}`#{@args[:db].esc_col(key.to_s + "_id")}` = '#{@args[:db].esc(val.id.to_s.sql)}'"
				found = true
			elsif args.has_key?(:cols_str) and match = key.match(/^([A-z_\d]+)_search$/) and args[:cols_str].index(match[1]) != nil
				Knj::Strings.searchstring(val).each do |str|
					sql_where += " AND #{table}`#{@args[:db].esc_col(match[1])}` LIKE '%#{@args[:db].esc(str)}%'"
				end
				found = true
			elsif args.has_key?(:cols_str) and match = key.match(/^([A-z_\d]+)_not$/) and args[:cols_str].index(match[1]) != nil
				sql_where += " AND #{table}`#{@args[:db].esc_col(match[1])}` != '#{@args[:db].esc(val)}'"
				found = true
			end
			
			list_args.delete(key) if found
		end
		
		sql_limit = false
		if limit_from and limit_to
			sql_limit = " LIMIT #{limit_from}, #{limit_to}"
		end
		
		return {
			:sql_where => sql_where,
			:sql_limit => sql_limit
		}
	end
end