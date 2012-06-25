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
    
    ls = Gtk::ListStore.new(String, String)
    cr = Gtk::CellRendererText.new
    self.pack_start(cr, false)
    self.add_attribute(cr, "text", 0)
    
    if items.is_a?(Array)
      items.each do |appendob|
        iter = ls.append
        
        if appendob.is_a?(String)
          iter[0] = appendob
        elsif appendob.respond_to?(:is_knj?)
          iter[0] = appendob.title
          @knj[:items] << {
            :iter => iter,
            :object => appendob
          }
        end
      end
    elsif items.is_a?(Hash)
      @knj[:type] = :hash
      
      items.each do |key, val|
        iter = ls.append
        iter[0] = val
        
        @knj[:items] << {
          :iter => iter,
          :object => key
        }
      end
    else
      raise "Unsupported type: '#{items.class.name}'."
    end
    
    self.model = ls
    self.active = 0
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
end