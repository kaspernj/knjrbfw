require "knj/jruby-gtk2/gtk2.rb"

button = Gtk::Button.new("Test")
button.connect("clicked") do
	print "Clicked!\n"
end

win = Gtk::Window.new("Trala")
win.add(button)
win.show_all

win.connect("destroy") do
	print "Destroy!\n"
	Gtk.main_quit
end

Gtk.main