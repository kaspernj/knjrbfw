require "knj/autoload"

class TestWindow
  def initialize
    @gui = Gtk::Builder.new
    @gui.add_from_file("test_builder.ui")
    @gui.connect_signals(){|h|method(h)}
    
    @gui["window1"].show_all
  end
  
  def on_window1_destroy
    Gtk.main_quit
  end
end

TestWindow.new

Gtk.main