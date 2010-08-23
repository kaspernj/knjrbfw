module Knj
	class Objects
		def initialize(paras)
			@callbacks = {}
			@paras = paras
			@paras.each do |key, value|
				if !key.is_a?(Symbol)
					@paras[key.to_sym] = value
					@paras.delete(key)
				end
			end
			
			if !@paras[:col_id]
				@paras[:col_id] = :id
			end
			
			@objects = {}
		end
		
		def connect(paras)
			if !paras["object"]
				raise "No object given."
			elsif !paras.has_key?("signal") and !paras.has_key?("signals")
				raise "No signals given."
			end
			
			if !@callbacks[paras["object"]]
				@callbacks[paras["object"]] = {}
			end
			
			@callbacks[paras["object"]][@callbacks[paras["object"]].length.to_s] = paras
		end
		
		def call(paras)
			classstr = paras["object"].class.to_s
			
			if @callbacks[classstr]
				@callbacks[classstr].each do |callback_key, callback|
					docall = false
					
					if callback.has_key?("signal") and paras.has_key?("signal") and callback["signal"] == paras["signal"]
						docall = true
					elsif callback["signals"] and paras["signal"] and callback["signals"].index(paras["signal"]) != nil
						docall = true
					end
					
					if docall
						Php.call_user_func(callback["callback"], paras)
					end
				end
			end
		end
		
		def requireclass(classname)
			classname = classname.to_s
			
			if !Php.class_exists(classname)
				filename = @paras[:class_path] + "/class_#{classname.downcase}.rb"
				filename_req = @paras[:class_path] + "/class_#{classname.downcase}"
				
				if !File.exists?(filename)
					raise "Class file could not be found: #{filename}."
				end
				
				require(filename_req)
			end
		end
		
		def get(classname, data)
			classname = classname.to_sym
			
			if data.is_a?(Hash) and data[@paras[:col_id].to_sym]
				id = data[@paras[:col_id].to_sym].to_i
			elsif data.is_a?(Hash) and data[@paras[:col_id].to_s]
				id = data[@paras[:col_id].to_s].to_i
			elsif data.is_a?(Integer) or data.is_a?(String) or data.is_a?(Fixnum)
				id = data.to_i
			else
				raise Knj::Errors::InvalidData.new("Unknown data: #{data.class.to_s}.")
			end
			
			if !@objects[classname]
				@objects[classname] = {}
			end
			
			if !@objects[classname][id]
				self.requireclass(classname)
				@objects[classname][id] = Kernel.const_get(classname).new(data)
			end
			
			return @objects[classname][id]
		end
		
		def list(classname, paras = {}, &block)
			classname = classname.to_sym
			self.requireclass(classname)
			classob = Kernel.const_get(classname)
			
			if !classob.respond_to?("list")
				raise "list-function has not been implemented for " + classname
			end
			
			if block_given?
				objects_return = classob.list(paras, &block)
				if objects_return
					objects_return.each do |object|
						block.call(object)
					end
				end
			else
				return classob.list(paras)
			end
		end
		
		def list_opts(classname, paras = {})
			classname = classname.to_sym
			
			if paras["list_paras"]
				obs = self.list(classname, paras["list_paras"])
			else
				obs = self.list(classname)
			end
			
			html = ""
			
			if paras["addnew"]
				html += "<option"
				
				if !paras["selected"]
					html += " selected=\"selected\""
				end
				
				html += " value=\"\">#{_("Add new")}</option>"
			end
			
			obs.each do |object|
				html += "<option value=\"" + CGI.escapeHTML(object[@paras[:col_id]]) + "\""
				
				if paras["selected"] and paras["selected"][@paras[:col_id]] == object[@paras[:col_id]]
					html += " selected=\"selected\""
				end
				
				html += ">" + CGI.escapeHTML(object.title) + "</option>"
			end
			
			return html
		end
		
		def list_optshash(classname, paras = {})
			classname = classname.to_sym
			
			if paras["list_paras"]
				obs = self.list(classname, paras["list_paras"])
			else
				obs = self.list(classname)
			end
			
			if Php.class_exists("Dictionary")
				list = Dictionary.new
			else
				list = Hash.new
			end
			
			if paras["addnew"]
				list["0"] = _("Add new")
			elsif paras["choose"]
				list["0"] = _("Choose") + ":"
			elsif paras["all"]
				list["0"] = _("All")
			elsif paras["none"]
				list["0"] = _("None")
			end
			
			obs.each do |object|
				list[object[@paras[:col_id]]] = object.title
			end
			
			return list
		end
		
		def list_bysql(classname, sql, &block)
			classname = classname.to_sym
			
			ret = []
			q_obs = @paras[:db].query(sql)
			while d_obs = q_obs.fetch
				if block_given?
					block.call(self.get(classname, d_obs))
				else
					ret << self.get(classname, d_obs)
				end
			end
			
			if !block_given?
				return ret
			end
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
			elsif !@objects[object.class.to_s.to_sym][object[@paras[:col_id]].to_i]
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
end