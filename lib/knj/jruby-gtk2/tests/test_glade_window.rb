#!/usr/bin/jruby

require "knj/autoload"
require "#{$knjpath}gtk2_tv"

class WinAppEdit
  def initialize
    print "Loading Glade.\n"
    @glade = GladeXML.new("test_glade_window.glade"){|h|method(h)}
    print "Done loading glade.\n"
    
    @glade["tvTest"].selection.signal_connect("changed") do
      print "test\n"
    end
    
    @glade["tvTest"].init(["ID", "Title"])
    @glade["tvTest"].append(["Test1", "Test2"])
    
    @glade["window"].show_all
  end
  
  def on_tvTest_row_activated
    #print "Test\n"
  end
  
  def on_btnSave_clicked(arg1)
    print arg1.to_s + "\n"
    print "Save clicked.\n"
    
    val = @glade["tvTest"].sel
    Php4r.print_r(val)
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