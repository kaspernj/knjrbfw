class Gtk::Image
	def initialize(*paras)
		if Gtk.takeob
			@ob = Gtk.takeob
			Gtk.takeob = nil
		else
			splitted = self.class.to_s.split("::")
			@ob = RealGtk.const_get(splitted.last).new(*paras)
		end
		
		if !@ob
			raise "Object was not spawned: #{self.class.to_s}"
		end
	end
end