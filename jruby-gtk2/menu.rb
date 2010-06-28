class Gtk::Menu
	def initialize
		if Gtk.takeob
			@ob = Gtk.takeob
			Gtk.takeob = nil
		else
			splitted = self.class.to_s.split("::")
			classname =  splitted[splitted.length - 1]
			class_spawn = Gtk.evalob("org.gnome.gtk." + classname)
			@ob = class_spawn.new
		end
	end
	
	def popup(arg1, arg2, event_button, event_time)
		@ob.popup
	end
	
	def prepend(object)
		@ob.prepend(object.ob)
	end
end

class Gtk::MenuItem
	def initialize(title)
		if Gtk.takeob
			@ob = Gtk.takeob
			Gtk.takeob = nil
		else
			splitted = self.class.to_s.split("::")
			classname =  splitted[splitted.length - 1]
			class_spawn = Gtk.evalob("org.gnome.gtk." + classname)
			
			if title
				@ob = class_spawn.new(title)
			else
				@ob = class_spawn.new
			end
		end
	end
end