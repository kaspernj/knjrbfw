module Gtk
	class StatusIcon
		def pixbuf=(newpixbuf)
			@ob.from_pixbuf = newpixbuf.ob
		end
	end
end

Gtk.events << ["StatusIcon", "activate", org.gnome.gtk.StatusIcon::Activate, :onActivate, nil]
Gtk.events << ["StatusIcon", "popup-menu", org.gnome.gtk.StatusIcon::PopupMenu, :onPopupMenu, nil]