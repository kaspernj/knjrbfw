class Gtk::Image
	def initialize(arg1, arg2)
		if Gtk.takeob
			@ob = Gtk.takeob
			Gtk.takeob = nil
		else
			@ob = Gtk.evalob("org.gnome.gtk.Image").new(arg1, arg2)
		end
	end
end