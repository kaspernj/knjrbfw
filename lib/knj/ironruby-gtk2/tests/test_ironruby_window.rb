require "gtk-sharp, Version=2.12.0.0, Culture=neutral, PublicKeyToken=35e10195dab3c99f"
require "glade-sharp, Version=2.12.0.0, Culture=neutral, PublicKeyToken=35e10195dab3c99f"

RealGtk = Gtk
RealGtk::Application.init

Gtk = Class.new do
  class Window
    def initialize(title = "")
      @ob = RealGtk::Window.new(title)
    end
    
    def add(widget)
      @ob.add(widget.ob)
    end
    
    def show_all
      @ob.show_all
    end
  end
  
  class Button
    def initialize(title = nil)
      @ob = RealGtk::Button.new(title)
    end
    
    def ob
      return @ob
    end
    
    def signal_connect(signal, &block)
      @ob.send(signal) do |sender, e|
        block.call
      end
    end
  end
  
  def self.main
    RealGtk::Application.run
  end
  
  def self.main_quit
    RealGtk::Application.quit
  end
end

require "test_2.rb"