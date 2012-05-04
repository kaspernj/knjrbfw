#Contains various methods for doing stuff quick using the Gtk2-extension.
module Knj::Gtk2
  #Autoloader.
  def self.const_missing(name)
    require "#{$knjpath}knj/gtk2_#{name.to_s.downcase}"
    return Knj::Gtk2.const_get(name)
  end
  
  #Alias for self.msgbox.
  def msgbox(*args, &block)
    return Knj::Gtk2.msgbox(*args, &block)
  end
  
  #Shows a dialog on the screen based on various arguments.
  #===Examples
  # Knj::Gtk2.msgbox("Message", "Title", "info")
  # Knj::Gtk2.msgbox("Question", "Title", "yesno") #=> "yes"|"no"|"cancel"|"close"
  def self.msgbox(paras, type = "warning", title = nil)
    if paras.is_a?(Array)
      msg = paras[0]
      title = paras[2]
      type = paras[1]
    elsif paras.is_a?(Hash)
      msg = paras["msg"]
      title = paras["title"]
      type = paras["type"]
    elsif paras.is_a?(String) or paras.is_a?(Integer)
      msg = paras
    else
      raise "Cant handle the parameters: " + paras.class.to_s
    end
    
    type = "info" if !type
    
    if !title
      if type == "yesno"
        title = "Question"
      elsif type == "info"
        title = "Message"
      else
        title = "Warning"
      end
    end
    
    close_sig = "close"
    cancel_sig = "cancel"
    ok_sig = "ok"
    yes_sig = "yes"
    no_sig = "no"
    
    box = Gtk::HBox.new
    
    if type == "yesno"
      button1 = [Gtk::Stock::YES, Gtk::Dialog::RESPONSE_YES]
      button2 = [Gtk::Stock::NO, Gtk::Dialog::RESPONSE_NO]
      
      image = Gtk::Image.new(Gtk::Stock::DIALOG_QUESTION, Gtk::IconSize::DIALOG)
    elsif type == "warning"
      button1 = [Gtk::Stock::OK, Gtk::Dialog::RESPONSE_OK]
      image = Gtk::Image.new(Gtk::Stock::DIALOG_WARNING, Gtk::IconSize::DIALOG)
    elsif type == "info"
      button1 = [Gtk::Stock::OK, Gtk::Dialog::RESPONSE_OK]
      image = Gtk::Image.new(Gtk::Stock::DIALOG_INFO, Gtk::IconSize::DIALOG)
    elsif type == "list"
      close_sig = false
      cancel_sig = false
      
      button1 = [Gtk::Stock::OK, Gtk::Dialog::RESPONSE_OK]
      
      tv = Gtk::TreeView.new
      tv.init([_("ID"), _("Title")])
      tv.columns[0].visible = false
      
      if paras["items"].is_a?(Hash)
        paras["items"].each do |key, value|
          tv.append([key, value])
        end
      elsif paras["items"].is_a?(Array)
        count = 0
        paras["items"].each do |element|
          if element.respond_to?("id") and element.respond_to?("title")
            tv.append([count.to_s, element.title])
          else
            raise "Could not handle object in array: " + element.class.to_s
          end
          
          count += 1
        end
      else
        raise "Unhandeled class: " + items.class.to_s
      end
      
      sw = Gtk::ScrolledWindow.new
      sw.add(tv)
      
      box.pack_start(sw)
    else
      raise "No such mode: " + type
    end
    
    if button1 and button2
      dialog = Gtk::Dialog.new(title, nil, Gtk::Dialog::MODAL, button1, button2)
    else
      dialog = Gtk::Dialog.new(title, nil, Gtk::Dialog::MODAL, button1)
    end
    
    if image
      box.pack_start(image)
    end
    
    if msg
      box.pack_start(Gtk::Label.new(msg))
    end
    
    box.spacing = 15
    dialog.border_width = 5
    dialog.vbox.add(box)
    dialog.has_separator = false
    dialog.show_all
    
    if type == "list"
      dialog.set_size_request(250, 370)
      tv.grab_focus
    end
    
    response = dialog.run
    
    if type == "list"
      sel = tv.sel
      
      if sel and sel[0]
        if paras["items"].is_a?(Array) and paras["items"].length > 0 and sel and sel[0]
          trala = sel[0].to_i
          ok_sig = paras["items"][sel[0].to_i]
        else
          ok_sig = sel[0]
        end
      else
        ok_sig = false
      end
    end
    
    dialog.destroy
    
    if response == Gtk::Dialog::RESPONSE_OK
      return ok_sig
    elsif response == Gtk::Dialog::RESPONSE_YES
      return yes_sig
    elsif response == Gtk::Dialog::RESPONSE_NO
      return no_sig
    elsif response == Gtk::Dialog::RESPONSE_CANCEL
      return cancel_sig
    elsif response == Gtk::Dialog::RESPONSE_CLOSE or response == Gtk::Dialog::RESPONSE_DELETE_EVENT
      return close_sig
    else
      raise "Unknown response: " + response.to_s
    end
  end
  
  #Takes a Gtk::Builder-object and runs labels and titles through GetText.gettext in order to translate them.
  #===Examples
  # Knj::Gtk2.translate(builder_obj)
  def self.translate(builderob)
    builderob.objects.each do |object|
      class_str = object.class.to_s
      
      if object.is_a?(Gtk::Label) or object.is_a?(Gtk::Button)
        object.label = GetText.gettext(object.label)
      elsif object.is_a?(Gtk::Window)
        object.title = GetText.gettext(object.title)
      end
    end
  end
  
  #Makes a Gtk::Table based on the given arguments.
  #===Examples
  # Knj::Gtk2.form([{"type" => "text", "name" => "txtname", "title" => _("Name")}]) #=> {"table" => <Gtk::Table>, "objects" => <Array>}
  def self.form(paras)
    table = Gtk::Table.new(paras.length, 2)
    table.row_spacings = 4
    table.column_spacings = 4
    top = 0
    objects = {}
    
    paras.each do |item|
      if !item["type"]
        if item["name"][0..2] == "txt" or item["name"][0..2] == "tex"
          item["type"] = "text"
        elsif item["name"][0..2] == "sel"
          item["type"] = "select"
        elsif item["name"][0..2] == "che"
          item["type"] = "check"
        else
          raise "Could not figure out type for: " + item["name"]
        end
      end
      
      if item["type"] == "text" or item["type"] == "password"
        label = Gtk::Label.new(item["title"])
        label.xalign = 0
        text = Gtk::Entry.new
        
        if item["type"] == "password"
          text.visibility = false
        end
        
        if item["default"]
          text.text = item["default"]
        end
        
        table.attach(label, 0, 1, top, top + 1, Gtk::FILL, Gtk::FILL)
        table.attach(text, 1, 2, top, top + 1, Gtk::EXPAND | Gtk::FILL, Gtk::SHRINK)
        
        objects[item["name"]] = {
          "type" => "text",
          "object" => text
        }
      elsif item["type"] == "check"
        check = Gtk::CheckButton.new(item["title"])
        table.attach(check, 0, 2, top, top + 1, Gtk::EXPAND | Gtk::FILL, Gtk::SHRINK)
        
        objects[item["name"]] = {
          "type" => "check",
          "object" => check
        }
      elsif item["type"] == "select"
        label = Gtk::Label.new(item["title"])
        label.xalign = 0
        
        cb = Gtk::ComboBox.new
        cb.init(item["opts"])
        
        table.attach(label, 0, 1, top, top + 1, Gtk::FILL, Gtk::FILL)
        table.attach(cb, 1, 2, top, top + 1, Gtk::EXPAND | Gtk::FILL, Gtk::SHRINK)
        
        objects[item["name"]] = {
          "type" => "text",
          "object" => cb
        }
      else
        raise "Unknown type: " + item["type"]
      end
      
      
      top += 1
    end
    
    return {
      "table" => table,
      "objects" => objects
    }
  end
  
  #Takes a given object and sets its value.
  #===Examples
  # Knj::Gtk2.form_setval(text_obj, "Hejsa")
  # Knj::Gtk2.form_setval(checkbox_obj, 1)
  def self.form_setval(object, val)
    if object.is_a?(Gtk::Entry)
      object.text = val.to_s
    elsif object.is_a?(Gtk::CheckButton)
      if val.to_s == "1"
        object.active = true
      else
        object.active = false
      end
    elsif object.is_a?(Gtk::ComboBox)
      object.sel = val.to_s
    end
  end
  
  #Returns the value of an object regardless of that type the object is.
  #===Examples
  # Knj::Gtk2.form_getval(text_obj) #=> "Hejsa"
  # Knj::Gtk2.form_getval(checkbox_obj) #=> "1"
  def self.form_getval(object)
    if object.is_a?(Gtk::Entry)
      return object.text
    elsif object.is_a?(Gtk::CheckButton)
      if object.active?
        return "1"
      else
        return "0"
      end
    elsif object.is_a?(Gtk::ComboBox)
      sel = object.sel
      return sel["text"]
    else
      raise "Unknown object: #{object.class.name}"
    end
  end
end

#Defines a shortcut-method on Gtk::Builder
class Gtk::Builder
  #Proxies to Knj::Gtk2.translate
  def translate
    return Knj::Gtk2.translate(self)
  end
end