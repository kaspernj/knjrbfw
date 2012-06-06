class Knj::Gtk2::Window
  require "wref"
  @@uniques = Wref_map.new
  
  def self.unique!(id)
    instance = @@uniques.get!(id)
    
    if instance and !instance.gui["window"].destroyed?
      instance.gui["window"].activate_focus
    else
      obj = yield
      @@uniques[id] = obj
    end
  end
end