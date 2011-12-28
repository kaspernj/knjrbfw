class GladeXML
  def block=(newblock); @block = newblock; end
  def data; return @data; end
  
  def initialize(filename, &block)
    @obs = {}
    
    if filename.index("interface>") == nil
      @cont = File.read(filename)
      @data = XmlSimple.xml_in(@cont)
      window_name = self.find_window(data)
      @glade = Glade::XML.new(filename, window_name, nil)
    else
      @cont = filename
      @data = XmlSimple.xml_in(@cont)
      window_name = self.find_window(data)
      Knj::Php.file_put_contents("temp.glade", @cont)
      @glade = Glade::XML.new("temp.glade", window_name, nil)
      FileUtils.rm("temp.glade")
    end
    
    if block_given?
      @block = block
      self.auto_connect(@data)
    end
  end
  
  def auto_connect(data)
    data.each do |item|
      if item[0] == "widget"
        if item[1][0]["signal"]
          tha_class = item[1][0]["class"]
          tha_id = item[1][0]["id"]
          func_name = item[1][0]["signal"][0]["handler"]
          name = item[1][0]["signal"][0]["name"]
          
          method = @block.call(func_name)
          
          object = self.get_widget(tha_id)
          object.signal_connect(name) do |*paras|
            #Convert arguments to fit the arity-count of the Proc-object (the block, the method or whatever you want to call it).
            newparas = []
            0.upto(method.arity - 1) do |number|
              if paras[number]
                newparas << paras[number]
              end
            end
            
            method.call(*newparas)
          end
        end
      end
      
      if item.is_a?(Array) or item.is_a?(Hash)
        self.auto_connect(item)
      end
    end
  end
  
  def find_window(data)
    match = @cont.match(/<(object|widget) class="GtkWindow" id="(.+?)">/)
    if match
      print "GladeXML: Window-name matched from content - dont do slow XML-go-through.\n"
      return match[2]
    end
    
    data.each do |item|
      if item[0] == "widget"
        class_str = item[1][0]["class"]
        
        if class_str == "GtkWindow"
          ret = item[1][0]["id"]
          if ret.is_a?(String)
            return ret
          end
        end
      elsif item.is_a?(Array) or item.is_a?(Hash)
        ret = self.find_window(item)
        if ret.is_a?(String)
          return ret
        end
      end
    end
  end
  
  def get_widget(wname)
    if @obs[wname]
      return @obs[wname]
    end
    
    widget = @glade[wname]
    Gtk.takeob = widget
    
    splitted = widget.class.to_s.split("::")
    conv_widget = Gtk.const_get(splitted.last).new
    @obs[wname] = conv_widget
    
    return conv_widget
  end
  
  def [](wname)
    return self.get_widget(wname)
  end
end