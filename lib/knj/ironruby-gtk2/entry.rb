Gtk.events["Gtk"]["Entry"] = {
  "activate" => "activate"
}

class Gtk::Entry
  def set_text(newtext)
    @ob.text = newtext
  end
end