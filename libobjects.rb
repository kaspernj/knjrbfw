module Knj
	class Objects
		def initialize(paras)
			@paras = paras
			
			if (!@paras["col_id"])
				@paras["col_id"] = "id"
			end
			
			@objects = {}
		end
		
		def requireclass(classname)
			filename = @paras["class_path"] + "/class_" + classname.downcase + ".rb"
			
			if (!File.exists?(filename))
				raise "Class file could not be found: " + filename
			end
			
			require(filename)
		end
		
		def get(classname, data)
			if data.is_a?(Hash) and data[@paras["col_id"]]
				id = data[@paras["col_id"]].to_i
			elsif data.is_a?(Integer) or data.is_a?(String) or data.is_a?(Fixnum)
				id = data.to_i
			else
				raise "Unknown data: " + data.class.to_s
			end
			
			if (!@objects[classname])
				@objects[classname] = []
			end
			
			if (!@objects[classname][id])
				self.requireclass(classname)
				@objects[classname][id] = Kernel.const_get(classname).new(data)
			end
			
			return @objects[classname][id]
		end
		
		def list(classname, paras = {})
			self.requireclass(classname)
			return Kernel.const_get(classname).list(paras)
		end
		
		def list_opts(classname, paras = {})
			if (paras["list_paras"])
				obs = self.list(classname, paras["list_paras"])
			else
				obs = self.list(classname)
			end
			
			html = ""
			
			if (paras["addnew"])
				html += "<option"
				
				if (!paras["selected"])
					html += " selected=\"selected\""
				end
				
				html += " value=\"\">" + gettext("Add new") + "</option>"
			end
			
			obs.each do |object|
				if (!object.paras["col_title"])
					raise "'col_title' has not been set for the class: '" + object.class.to_s + "'."
				end
				
				html += "<option value=\"" + CGI.escapeHTML(object[@paras["col_id"]]) + "\""
				
				if (paras["selected"] and paras["selected"][@paras["col_id"]] == object[@paras["col_id"]])
					html += " selected=\"selected\""
				end
				
				html += ">" + CGI.escapeHTML(object[object.paras["col_title"]]) + "</option>"
			end
			
			return html
		end
		
		def add(classname, data)
			self.requireclass(classname)
			return Kernel.const_get(classname).add(data)
		end
		
		def unset(object)
			if (!@objects[object.class.to_s] or !@objects[object.class.to_s][object[@paras["col_id"]].to_i])
				raise "Could not find object in cache."
			end
			
			@objects[object.class.to_s].delete(object)
		end
		
		def delete(object)
			self.unset(object)
			object.delete
		end
	end
end