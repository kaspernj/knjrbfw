require "knj/jruby-gtk2/gtk2.rb"
require "knj/jruby-gtk2/gladexml.rb"

class WinAppEdit
	def initialize
		@glade = GladeXML.new("win_app_edit.glade"){|h|method(h)}
		@glade["window"].show_all
	end
	
	def on_btnSave_clicked(arg1)
		print arg1.to_s + "\n"
		print "Save clicked.\n"
	end
	
	def on_btnCancel_clicked
		print "Cancel clicked.\n"
	end
	
	def on_window_destroy
		print "Destroyed!\n"
		Gtk.main_quit
	end
end

WinAppEdit.new

Gtk.main