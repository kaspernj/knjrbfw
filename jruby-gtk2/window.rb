Gtk.events << ["Window", "destroy", org.gnome.gtk.Window::DeleteEvent, :onDeleteEvent, false]

module Gtk
	class Window
		def destroy
			@ob.hide #destroy does not exist in the Java-version? - knj
		end
		
		def set_frame_dimensions(arg1, arg2, arg3, arg4)
			@ob.border_width = arg1
		end
	end
end