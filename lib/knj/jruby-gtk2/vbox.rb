class Gtk::VBox
	def initialize
		if Gtk.takeob
			@ob = Gtk.takeob
			Gtk.takeob = nil
		else
			splitted = self.class.to_s.split("::")
			javaname = "org.gnome." + splitted.first.downcase + "." + splitted.last
			@ob = Gtk.evalob(javaname).new(false, 0)
		end
	end
end