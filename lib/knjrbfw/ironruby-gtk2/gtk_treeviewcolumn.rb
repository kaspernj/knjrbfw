class Gtk::TreeViewColumn
	def initialize(title, renderer, *paras)
		@title = title
		@renderer = renderer
		
		if Gtk.takeob
			@ob = Gtk.takeob
			if !@ob
				raise "Gtk.takeob was not set correctly: " + @ob.class.to_s
			end
			
			Gtk.takeob = nil
		else
			splitted = self.class.to_s.split("::")
			realclass = "Real#{splitted.first}"
			classob = Kernel.const_get(realclass).const_get(splitted.last)
			
			if !classob
				raise "Class does not exist: " + realclass + "::" + splitted.last
			end
			
			@ob = classob.new
			
			if !@ob
				raise "Object was not spawned: #{self.class.to_s}, #{@ob.class.to_s}, #{realclass}::#{splitted.last}"
			end
			
			@ob.pack_start(renderer.ob, true)
			#@ob.add_attribute(renderer.ob, "text", 0)
		end
	end
end