class Knj::Gtk2::Menu
  def initialize(paras)
    @paras = paras
    @items = []
    @mainmenu = Gtk::Menu.new
    @signal = ""
    
    count = 0
    if @paras["items"].respond_to?("reverse")
      items = @paras["items"].reverse
    else
      items = @paras["items"]
    end
    
    if items.is_a?(Array)
      items = Knj::ArrayExt.dict(items)
    end
    
    items.each do |signal, menuitem|
      if menuitem.is_a?(Array)
        old_mi = menuitem
        menuitem = {"text" => menuitem[0], "connect" => menuitem[1]}
      end
      
      newitem = Gtk::MenuItem.new(menuitem["text"])
      
      if menuitem["connect"]
        newitem.signal_connect("activate") do
          Knj::Php.call_user_func(menuitem["connect"])
        end
      else
        newitem.signal_connect("activate") do
          on_menuitem_activate
        end
      end
      
      @items[count] = {
        "gtkmenuitem" => newitem,
        "signal" => signal
      }
      @mainmenu.prepend(newitem)
      
      count += 1
    end
    
    event = Gdk::EventButton.new(Gdk::Event::BUTTON_PRESS)
    
    @mainmenu.show_all
    @mainmenu.popup(nil, nil, event.button, event.time)
  end
  
  def on_menuitem_activate(signal)
    @signal = signal
  end
  
  def signal() return @signal end
end