class Gtk::CellRendererText
  def initialize
    if Gtk.takeob
      @ob = Gtk.takeob
      Gtk.takeob = nil
    end
  end
  
  def init(tcol)
    @ob = org.gnome.gtk.CellRendererText.new(tcol.ob)
  end
end