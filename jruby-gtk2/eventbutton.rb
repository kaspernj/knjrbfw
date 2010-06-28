module Gdk
	class EventButton
		def initialize(eventtype)
			if Gtk.takeob
				@ob = Gtk.takeob
				Gtk.takeob = nil
			else
				splitted = self.class.to_s.split("::")
				classname =  splitted[splitted.length - 1]
				class_spawn = Gtk.evalob("org.gnome.gdk." + classname)
				#@ob = class_spawn.new
			end
		end
		
		def button
			return 2
		end
		
		def time
			return 0
		end
	end
end