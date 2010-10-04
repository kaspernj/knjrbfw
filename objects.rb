class Knj::Objects
	def initialize(args)
		@callbacks = {}
		@args = ArrayExt.hash_sym(args)
		@args[:col_id] = :id if !@args[:col_id]
		raise "No DB given." if !@args[:db]
		@args[:class_pre] = "class_" if !@args[:class_pre]
		@objects = {}
	end
	
	def count_objects
		count = 0
		@objects.each do |key, value|
			value.each do |id, object|
				count += 1
			end
		end
		
		return count
	end
	
	def clean
		@objects = {}
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
		classname = classname.to_s
		
		if !Php.class_exists(classname)
			filename = @args[:class_path] + "/#{@args[:class_pre]}#{classname.downcase}.rb"
			filename_req = @args[:class_path] + "/#{@args[:class_pre]}#{classname.downcase}"
			raise "Class file could not be found: #{filename}." if !File.exists?(filename)
			require(filename_req)
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
			@objects[classname][id] = Kernel.const_get(classname).new(data)
		end
		
		return @objects[classname][id]
	end
	
	def list(classname, args = {}, &block)
		classname = classname.to_sym
		self.requireclass(classname)
		classob = Kernel.const_get(classname)
		
		raise "list-function has not been implemented for #{classname}" if !classob.respond_to?("list")
		
		if block_given?
			objects_return = classob.list(args, &block)
			if objects_return
				objects_return.each do |object|
					block.call(object)
				end
			end
		else
			return classob.list(args)
		end
	end
	
	def list_opts(classname, args = {})
		ArrayExt.hash_sym(args)
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
			html += ">#{object.title.html}</option>"
		end
		
		return html
	end
	
	def list_optshash(classname, args = {})
		ArrayExt.hash_sym(args)
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
	
	def add(classname, data)
		classname = classname.to_sym
		self.requireclass(classname)
		retob = Kernel.const_get(classname).add(data)
		self.call("object" => retob, "signal" => "add")
		return retob
	end
	
	def unset(object)
		if !@objects.has_key?(object.class.to_s.to_sym)
			raise "Could not find object class in cache."
		elsif !@objects[object.class.to_s.to_sym][object[@args[:col_id]].to_i]
			print "Could not unset object from cache.\n"
			print "Class: #{object.class.to_s}.\n"
			print "ID: #{object.id}.\n"
			
			Php.print_r(@objects[object.class.to_s])
			
			exit
			raise "Could not find object ID in cache."
		else
			@objects[object.class.to_s.to_sym].delete(object)
		end
	end
	
	def delete(object)
		self.call("object" => object, "signal" => "delete_before")
		self.unset(object)
		object.delete
		self.call("object" => object, "signal" => "delete")
	end
end