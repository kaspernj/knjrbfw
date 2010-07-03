require "knj/autoload"

button = Gtk::Button.new("Test")
button.signal_connect("clicked") do
	print "Clicked!\n"
end

win = Gtk::Window.new("Trala")
win.add(button)
win.show_all

win.signal_connect("destroy") do
	print "Destroy!\n"
	Gtk.main_quit
end

Gtk.main