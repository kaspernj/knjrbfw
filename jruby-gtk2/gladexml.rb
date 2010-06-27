class GladeXML
	def initialize(filename, &block)
		@obs = {}
		
		require "xmlsimple"
		
		cont = File.read(filename)
		data = XmlSimple.xml_in(cont)
		
		window_name = self.find_window(data)
		
		@glade = org.gnome.glade.Glade::parse(filename, window_name)
		
		if block_given?
			@block = block
			self.auto_connect(data)
		end
	end
	
	def auto_connect(data)
		data.each do |item|
			if item[0] == "widget"
				if item[1][0]["signal"]
					tha_class = item[1][0]["class"]
					tha_id = item[1][0]["id"]
					func_name = item[1][0]["signal"][0]["handler"]
					name = item[1][0]["signal"][0]["name"]
					
					method = @block.call(func_name)
					
					object = self.get_widget(tha_id)
					object.signal_connect(name) do |*paras|
						#Convert arguments to fit the arity-count of the Proc-object (the block, the method or whatever you want to call it).
						newparas = []
						0.upto(method.arity - 1) do |number|
							if paras[number]
								newparas << paras[number]
							end
						end
						
						method.call(*newparas)
					end
				end
			end
			
			if item.is_a?(Array) or item.is_a?(Hash)
				self.auto_connect(item)
			end
		end
	end
	
	def find_window(data)
		data.each do |item|
			if item[0] == "widget"
				class_str = item[1][0]["class"]
				
				if class_str == "GtkWindow"
					return item[1][0]["id"]
				end
			elsif item.is_a?(Array) or item.is_a?(Hash)
				ret = self.find_window(item)
				if ret
					return ret
				end
			end
		end
	end
	
	def get_widget(wname)
		if @obs[wname]
			return @obs[wname]
		end
		
		widget = @glade.get_widget(wname)
		
		Gtk.takeob = widget
		splitted = widget.class.to_s.split("::")
		conv_widget = Gtk.const_get(splitted.last).new
		
		@obs[wname] = conv_widget
		
		return conv_widget
	end
	
	def [](wname)
		return self.get_widget(wname)
	end
end