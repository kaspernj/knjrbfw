class Gtk::VBox
  def pack_start(widget, arg1 = false, arg2 = false)
    @ob.PackStart(widget.ob)
  end
end