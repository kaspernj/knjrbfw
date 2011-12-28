class Gtk::Dialog
  RESPONSE_OK = RealGtk::ResponseType.Ok
  RESPONSE_YES = RealGtk::ResponseType.Yes
  RESPONSE_NO = RealGtk::ResponseType.No
  RESPONSE_CANCEL = RealGtk::ResponseType.Cancel
  RESPONSE_CLOSE = RealGtk::ResponseType.Close
  RESPONSE_DELETE_EVENT = RealGtk::ResponseType.DeleteEvent
  MODAL = 0
  
  def initialize(*paras)
    if Gtk.takeob
      @ob = Gtk.takeob
      Gtk.takeob = nil
    else
      splitted = self.class.to_s.split("::")
      @ob = RealGtk.const_get(splitted.last).new(*paras)
    end
    
    if paras.length > 3
      3.upto(paras.length) do |count|
        data = paras[count]
        
        if data.is_a?(Array)
          @ob.method(:add_button).overload(System::String, RealGtk::ResponseType).call(data[0], data[1])
        elsif data.is_a?(NilClass)
          #do nothing.
        else
          #raise "Unhandeled data: #{data.class.to_s}"
        end
      end
    end
    
    if !@ob
      raise "Object was not spawned: #{self.class.to_s}"
    end
  end
  
  def vbox
    Gtk.takeob = @ob.VBox
    conv_widget = Gtk::VBox.new
    
    return conv_widget
  end
end