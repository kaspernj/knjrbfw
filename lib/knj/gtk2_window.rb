#Containing various helper methods for Gtk2-windows.
class Knj::Gtk2::Window
  require "wref"
  @@uniques = Wref_map.new
  
  #Used to make a window-instance unique. If it already exists when unique! is called, then it will pass focus to the existing window instead of yielding the block, which should contain code to create the window.
  #===Examples
  #This should only create a single window.
  # Knj::Gtk2::Window.unique!("my_window") do
  #  Gtk::Window.new
  # end
  # 
  # Knj::Gtk2::Window.unique!("my_window") do
  #  Gtk::Window.new
  # end
  def self.unique!(id)
    instance = @@uniques.get!(id)
    
    if instance and !instance.gui["window"].destroyed?
      instance.gui["window"].present
    else
      obj = yield
      @@uniques[id] = obj
    end
  end
end