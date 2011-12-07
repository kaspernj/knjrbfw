class Gtk::TreeIter
  def initialize(*paras)
    if Gtk.takeob
      print "TreeIter from takeob.\n"
      @ob = Gtk.takeob
      Gtk.takeob = nil
    else
      print "TreeIter from constructor.\n"
      @ob = RealGtk::TreeIter.new(*paras)
    end
  end
  
  def liststore=(newliststore)
    @liststore = newliststore
  end
  
  def []=(key, value)
    return @liststore.ob.method(:set_value).overload(RealGtk::TreeIter, Fixnum, System::String).call(@ob, key, value)
  end
  
  def [](key)
    return @liststore.ob.get_value(@ob, key)
  end
end