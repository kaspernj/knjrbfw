class Gtk::ProgressBar
  def initialize
    if Gtk.takeob
      @ob = Gtk.takeob
      Gtk.takeob = nil
    else
      splitted = self.class.to_s.split("::")
      javaname = "org.gnome." + splitted.first.downcase + "." + splitted.last
      @ob = Gtk.evalob(javaname).new
    end
  end
end