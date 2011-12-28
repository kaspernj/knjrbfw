class Gtk::HBox
  def initialize(homogeneous = false, spacing = 0)
    if Gtk.takeob
      @ob = Gtk.takeob
      Gtk.takeob = nil
    else
      @ob = Gtk.evalob("org.gnome.gtk.HBox").new(homogeneous, spacing)
    end
  end
end