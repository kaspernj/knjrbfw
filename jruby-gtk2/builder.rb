class Gtk::Builder
	def initialize
		
	end
	
	def add_from_file(filename)
		cont = File.read(filename).gsub("<interface>", "<glade-interface>").gsub("</interface>", "</glade-interface>")
		cont = cont.gsub("<object", "<widget").gsub("</object>", "</widget>")
		cont = cont.gsub("<requires lib=\"gtk+\" version=\"2.16\"\/>", "")
		cont = cont.gsub("<child type=\"label\">", "<child>")
		
		@glade = GladeXML.new(cont)
	end
	
	def connect_signals(&block)
		@glade.block = block
		@glade.auto_connect(@glade.data)
	end
	
	def [](key)
		return @glade[key]
	end
	
	alias get_object []
end