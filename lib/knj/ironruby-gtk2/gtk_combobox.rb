class Gtk::ComboBox
  def pack_start(widget, val)
    @ob.pack_start(widget.ob, val)
    @ob.add_attribute(widget.ob, "text", 0)
  end
  
  def add_attribute(*paras)
    #this should not do anything.
  end
  
  def model=(newmodel)
    @model = newmodel
    @ob.model = newmodel.ob
  end
  
  def model
    return @model
  end
end