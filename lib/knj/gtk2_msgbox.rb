#This class holds various methods for message-box-functionality and debugging.
class Knj::Gtk2::Msgbox
  #This hash contains various data like the currently shown message-box.
  DATA = {}
  
  #Returns the label of the currently shown message-box.
  def self.cur_label
    raise "No message-box currentl shown." if !Knj::Gtk2::Msgbox::DATA[:current]
    return Knj::Gtk2::Msgbox::DATA[:current].children.first.children.first.children.last.label
  end
  
  #Send a response to the currently shown message-box.
  def self.cur_respond(response)
    raise "No message-box currentl shown." if !Knj::Gtk2::Msgbox::DATA[:current]
    id = Knj::Gtk2::Msgbox::DATA[:current].__id__
    Knj::Gtk2::Msgbox::DATA[:current].response(response)
    Thread.pass while Knj::Gtk2::Msgbox::DATA[:current] and Knj::Gtk2::Msgbox::DATA[:current].__id__ == id
    nil
  end
  
  #Returns true if a message-box is currently shown.
  def self.shown?
    return true if Knj::Gtk2::Msgbox::DATA[:current]
    return false
  end
end