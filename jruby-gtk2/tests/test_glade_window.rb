#!/usr/bin/jruby

print "Script started\n"

require "knj/php"

print "PHP loaded.\n"

require "knj/jruby-gtk2/gtk2"

print "jruby-gtk2 loaded.\n"

require "knj/jruby-gtk2/gladexml"

print "Glade loaded.\n"

require "knj/gtk2_tv"

print "Knj-Gtk2-tv loaded.\n"

class WinAppEdit
	def initialize
		print "Loading Glade.\n"
		@glade = GladeXML.new("test_glade_window.glade"){|h|method(h)}
		print "Done loading glade.\n"
		
		@glade["tvTest"].init(["ID", "Title"])
		@glade["tvTest"].append(["Test1", "Test2"])
		
		@glade["window"].show_all
	end
	
	def on_btnSave_clicked(arg1)
		print arg1.to_s + "\n"
		print "Save clicked.\n"
		
		val = @glade["tvTest"].sel
		Knj::Php.print_r(val)
	end
	
	def on_btnCancel_clicked
		print "Cancel clicked.\n"
	end
	
	def on_window_destroy
		print "Destroyed!\n"
		Gtk.main_quit
	end
end

print "Starting app.\n"
WinAppEdit.new

Gtk.main