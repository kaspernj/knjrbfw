module Knj::Gtk2::Tv
  def self.init(tv, columns)
    args = []
    columns.each do |pair|
      args << String
    end
    
    list_store = Gtk::ListStore.new(*args)
    tv.model = list_store
    
    count = 0
    columns.each do |col_title|
      renderer = Gtk::CellRendererText.new
      col = Gtk::TreeViewColumn.new(col_title, renderer, :text => count)
      tv.append_column(col)
      count += 1
    end
  end
  
  def self.append(tv, data)
    iter = tv.model.append
    
    count = 0
    data.each do |value|
      iter[count] = value.to_s
      count += 1
    end
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