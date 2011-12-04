Gtk.events["Gtk"]["TreeSelection"] = {
  "changed" => "changed"
}

class Gtk::TreeSelection
  def selected_rows
    ret = []
    sel_rows = @ob.GetSelectedRows
    sel_rows.each do |tpath|
      Gtk.takeob = tpath
      ret << Gtk::TreePath.new
    end
    
    return ret
  end
end