class Gdk::Pixbuf
	def initialize(*args)
		if Gtk.takeob
			@ob = Gtk.takeob
			Gtk.takeob = nil
		else
			@ob = Kernel.const_get("RealGdk").const_get("Pixbuf").method(:new).overload(System::String).call(System::String.new(args[0]))
			#method.call("")
		end
	end
end