#!/usr/bin/jruby

require "knj/autoload"

pixbuf = Gdk::Pixbuf.new("test_trayicon.png")

icon = Gtk::StatusIcon.new
icon.pixbuf = pixbuf

icon.connect("activate") do
	print "Activate\n"
end

icon.connect("popup-menu") do
	print "Popup-menu\n"
end

icon.show_all

Gtk.main