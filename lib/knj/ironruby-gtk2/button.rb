Gtk.events["Gtk"]["Button"] = {
  "clicked" => "clicked"
}

class Gtk::Button
  def initialize(title = "")
    if Gtk.takeob
      @ob = Gtk.takeob
      Gtk.takeob = nil
    else
      splitted = self.class.to_s.split("::")
      @ob = RealGtk.const_get(splitted.last).new(title)
    end
    
    if !@ob
      raise "Object was not spawned: #{self.class.to_s}"
    end
  end
end