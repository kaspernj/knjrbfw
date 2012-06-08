module Knj::Gtk2::Tv
  def self.init(tv, columns)
    ret = {
      :renderers => []
    }
    
    model_args = []
    columns.each do |args|
      if args.is_a?(String)
        args = {:type => :string, :title => args}
      end
      
      if args[:type] == :string
        model_args << String
      elsif args[:type] == :toggle
        model_args << Integer
      elsif args[:type] == :combo
        model_args << String
      else
        raise "Invalid type: '#{args[:type]}'."
      end
    end
    
    list_store = Gtk::ListStore.new(*model_args)
    tv.model = list_store
    
    count = 0
    columns.each do |args|
      if args.is_a?(String)
        args = {:type => :string, :title => args}
      end
      
      if args[:type] == :string
        renderer = Gtk::CellRendererText.new
        col = Gtk::TreeViewColumn.new(args[:title], renderer, :text => count)
        col.resizable = true
        tv.append_column(col)
      elsif args[:type] == :toggle
        renderer = Gtk::CellRendererToggle.new
        col = Gtk::TreeViewColumn.new(args[:title], renderer, :active => count)
        tv.append_column(col)
      elsif args[:type] == :combo
        renderer = Gtk::CellRendererCombo.new
        renderer.text_column = 0
        
        col = Gtk::TreeViewColumn.new(args[:title])
        col.pack_start(renderer, false)
        col.add_attribute(renderer, :text, count)
        
        renderer.model = args[:model] if args.key?(:model)
        tv.append_column(col)
      else
        raise "Invalid type: '#{args[:type]}'."
      end
      
      count += 1
      
      ret[:renderers] << renderer
    end
    
    return ret
  end
  
  def self.append(tv, data)
    iter = tv.model.append
    
    count = 0
    data.each do |value|
      col = tv.columns[count]
      renderer = col.cell_renderers.first
      
      if renderer.is_a?(Gtk::CellRendererText)
        iter[count] = value.to_s
      elsif renderer.is_a?(Gtk::CellRendererToggle)
        iter[count] = Knj::Strings.yn_str(value, 1, 0)
      elsif renderer.is_a?(Gtk::CellRendererCombo)
        iter[count] = value.to_s
      else
        raise "Unknown renderer: '#{renderer.class.name}'."
      end
      
      count += 1
    end
    
    return {:iter => iter}
  end
  
  def self.sel(tv)
    selected = tv.selection.selected_rows
    
    if !tv.model or selected.size <= 0
      return nil
    end
    
    iter = tv.model.get_iter(selected[0])
    returnval = []
    columns = tv.columns
    
    count = 0
    columns.each do |column|
      returnval[count] = iter[count]
      count += 1
    end
    
    return returnval
  end
end

class Gtk::TreeView
  def sel
    return Knj::Gtk2::Tv.sel(self)
  end
  
  def append(data)
    return Knj::Gtk2::Tv.append(self, data)
  end
  
  def init(cols)
    return Knj::Gtk2::Tv.init(self, cols)
  end
end