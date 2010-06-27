#!/usr/bin/jruby

require "knj/autoload"

pixbuf = Gdk::Pixbuf.new("test_trayicon.png")

icon = Gtk::StatusIcon.new
icon.pixbuf = pixbuf

icon.signal_connect("activate") do
	print "Activate\n"
end

icon.signal_connect("popup-menu") do
	print "Popup-menu\n"
end

Gtk.main