require "knj/autoload"

class MainWindow
  def initialize
    button = Gtk::Button.new("Test")
    
    button.signal_connect("clicked") do
      Gtk.main_quit
    end
    
    win = Gtk::Window.new
    win.add button
    win.show_all
  end

  def on_button1_clicked(object, event)
    print "hmm\n"
  end
end

main_window = MainWindow.new
Gtk.main