module Knj::Gtk2::Cb
  def self.init(paras)
    return paras["cb"].init(paras["items"])
  end
  
  def self.sel(cb)
    return cb.sel
  end
end

class Gtk::ComboBox
  def init(items)
    @knj = {
      :items => []
    }
    
    @ls = Gtk::ListStore.new(String, String)
    cr = Gtk::CellRendererText.new
    self.pack_start(cr, false)
    self.add_attribute(cr, "text", 0)
    
    if items.is_a?(Array)
      items.each do |appendob|
        if appendob.is_a?(String)
          iter = @ls.append
          iter[0] = appendob
        elsif appendob.respond_to?(:is_knj?)
          self.append_model(:model => appendob)
        end
      end
    elsif items.is_a?(Hash)
      @knj[:type] = :hash
      
      items.each do |key, val|
        iter = @ls.append
        iter[0] = val
        
        @knj[:items] << {
          :iter => iter,
          :object => key
        }
      end
    else
      raise "Unsupported type: '#{items.class.name}'."
    end
    
    self.model = @ls
    self.active = 0
  end
  
  #Appens a model to the list-store.
  def append_model(args)
    iter = @ls.append
    appendob = args[:model]
    
    if appendob.respond_to?(:name)
      iter[0] = appendob.name
    elsif appendob.respond_to?(:title)
      iter[0] = appendob.title
    else
      raise "Could not figure out of the name of the object."
    end
    
    @knj[:items] << {
      :iter => iter,
      :object => appendob
    }
    
    return {}
  end
  
  def sel
    iter = self.active_iter
    
    if @knj[:items].length > 0
      @knj[:items].each do |item|
        if item[:iter] == iter
          return item[:object]
        end
      end
      
      return false
    else
      return {
        "active" => self.active,
        "text" => iter[0]
      }
    end
  end
  
  def sel=(actob)
    if actob.respond_to?(:is_knj?)
      @knj[:items].each do |item|
        if item[:object].id == actob.id
          self.active_iter = item[:iter]
          return nil
        end
      end
    elsif @knj[:type] == :hash
      @knj[:items].each do |item|
        if item[:object] == actob
          self.active_iter = item[:iter]
          return nil
        end
      end
    else
      self.model.each do |model, path, iter|
        text = self.model.get_value(iter, 0)
        
        if text == actob
          self.active_iter = iter
          return nil
        end
      end
    end
    
    raise "Could not find such a row: '#{actob}'."
  end
  
  def resort
    @ls.set_sort_column_id(0)
    @ls.set_sort_func(0, &lambda{|iter1, iter2|
      item_id_1 = iter1[1].to_i
      item_id_2 = iter2[1].to_i
      
      item_name_1 = iter1[0].to_s.downcase
      item_name_2 = iter2[0].to_s.downcase
      
      if item_id_1 == 0
        return -1
      elsif item_id_2 == 0
        return 1
      else
        return item_name_1 <=> item_name_2
      end
    })
  end
end