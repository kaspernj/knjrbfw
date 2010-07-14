module Knj
	class Objects
		def initialize(paras)
			@callbacks = {}
			@paras = paras
			
			if !@paras["col_id"]
				@paras["col_id"] = "id"
			end
			
			@objects = {}
		end
		
		def connect(paras, &block)
			if !paras["object"]
				raise "No object given."
			elsif !paras.has_key?("signal") and !paras.has_key?("signals")
				raise "No signals given."
			end
			
			if block_given?
				paras["block"] = block
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
						if callback["block"]
							callback["block"].call
						elsif callback["callback"]
							Php.call_user_func(callback["callback"], paras)
						else
							raise "No valid callback given."
						end
					end
				end
			end
		end
		
		def requireclass(classname)
			if !Php.class_exists(classname)
				filename = @paras["class_path"] + "/class_" + classname.downcase + ".rb"
				filename_req = @paras["class_path"] + "/class_" + classname.downcase
				
				if !File.exists?(filename)
					raise "Class file could not be found: " + filename
				end
				
				require(filename_req)
			end
		end
		
		def get(classname, data)
			if data.is_a?(Hash) and data[@paras["col_id"]]
				id = data[@paras["col_id"]].to_i
			elsif data.is_a?(Integer) or data.is_a?(String) or data.is_a?(Fixnum)
				id = data.to_i
			else
				raise "Unknown data: " + data.class.to_s
			end
			
			if !@objects[classname]
				@objects[classname] = []
			end
			
			if !@objects[classname][id]
				self.requireclass(classname)
				@objects[classname][id] = Kernel.const_get(classname).new(data)
			end
			
			return @objects[classname][id]
		end
		
		def list(classname, paras = {})
			self.requireclass(classname)
			classob = Kernel.const_get(classname)
			
			if !classob.respond_to?("list")
				raise "list-function has not been implemented for " + classname
			end
			
			return classob.list(paras)
		end
		
		def list_opts(classname, paras = {})
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
				
				html += " value=\"\">" + gettext("Add new") + "</option>"
			end
			
			obs.each do |object|
				if !object.paras["col_title"]
					raise "'col_title' has not been set for the class: '" + object.class.to_s + "'."
				end
				
				html += "<option value=\"" + CGI.escapeHTML(object[@paras["col_id"]]) + "\""
				
				if paras["selected"] and paras["selected"][@paras["col_id"]] == object[@paras["col_id"]]
					html += " selected=\"selected\""
				end
				
				html += ">" + CGI.escapeHTML(object[object.paras["col_title"]]) + "</option>"
			end
			
			return html
		end
		
		def list_optshash(classname, paras = {})
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
				if !object.paras["col_title"]
					raise "'col_title' has not been set for the class: '#{object.class.to_s}'."
				end
				
				list[object[@paras["col_id"]]] = object[object.paras["col_title"]]
			end
			
			return list
		end
		
		def list_bysql(classname, sql)
			ret = []
			q_obs = @paras["db"].query(sql)
			while d_obs = q_obs.fetch
				ret << self.get(classname, d_obs)
			end
			
			return ret
		end
		
		def add(classname, data)
			self.requireclass(classname)
			retob = Kernel.const_get(classname).add(data)
			self.call("object" => retob, "signal" => "add")
			return retob
		end
		
		def unset(object)
			if !@objects.has_key?(object.class.to_s)
				raise "Could not find object class in cache."
			elsif !@objects[object.class.to_s][object[@paras["col_id"]].to_i]
				print "Class: " + object.class.to_s + "\n"
				print "ID: " + object.id + "\n"
				
				Php.print_r(@objects[object.class.to_s])
				
				exit
				raise "Could not find object ID in cache."
			else
				@objects[object.class.to_s].delete(object)
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