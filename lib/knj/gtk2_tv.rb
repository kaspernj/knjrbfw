#This module contains various helper-methods for handeling stuff regarding treeviews.
module Knj::Gtk2::Tv
  #Initializes a treeview with a model and a number of columns. Returns a hash containing various data like the renderers.
  #===Examples
  # Knj::Gtk2::Tv.init(treeview, ["ID", "Name"])
  def self.init(tv, args)
    ret = {
      :renderers => []
    }
    
    if args.is_a?(Array)
      columns = args
      args = {}
    else
      columns = args[:cols]
    end
    
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
    
    if args[:type] == :treestore
      list_store = Gtk::TreeStore.new(*model_args)
    else
      list_store = Gtk::ListStore.new(*model_args)
    end
    
    tv.model = list_store
    
    count = 0
    columns.each do |args|
      if args.is_a?(String)
        args = {:type => :string, :title => args}
      end
      
      if args[:type] == :string
        if args[:markup]
          col_args = {:markup => count}
        else
          col_args = {:text => count}
        end
        
        renderer = Gtk::CellRendererText.new
        col = Gtk::TreeViewColumn.new(args[:title], renderer, col_args)
        col.resizable = true
      elsif args[:type] == :toggle
        renderer = Gtk::CellRendererToggle.new
        col = Gtk::TreeViewColumn.new(args[:title], renderer, :active => count)
      elsif args[:type] == :combo
        renderer = Gtk::CellRendererCombo.new
        renderer.text_column = 0
        
        if args[:markup]
          col_args = {:markup => count}
        else
          col_args = {:text => count}
        end
        
        col = Gtk::TreeViewColumn.new(args[:title], renderer, col_args)
        col.resizable = true
        
        renderer.model = args[:model] if args.key?(:model)
        renderer.has_entry = args[:has_entry] if args.key?(:has_entry)
      else
        raise "Invalid type: '#{args[:type]}'."
      end
      
      col.spacing = 0
      col.reorderable = true
      col.sort_column_id = count
      
      if args.key?(:fixed_width)
        col.sizing = Gtk::TreeViewColumn::FIXED
      else
        col.sizing = Gtk::TreeViewColumn::AUTOSIZE
      end
      
      [:min_width, :max_width, :fixed_width, :expand, :spacing, :reorderable].each do |arg|
        col.__send__("#{arg}=", args[arg]) if args.key?(arg)
      end
      
      [:width_chars, :wrap_mode, :wrap_width].each do |arg|
        renderer.__send__("#{arg}=", args[arg]) if args.key?(arg)
      end
      
      tv.append_column(col)
      ret[:renderers] << renderer
      count += 1
    end
    
    return ret
  end
  
  #Appends data to the treeview.
  #===Examples
  # Knj::Gtk2::Tv.append(treeview, [1, "Kasper"])
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
  
  #Gets the selected data from the treeview.
  #===Examples
  # Knj::Gtk2::Tv.sel(treeview) #=> [1, "Kasper"]
  def self.sel(tv)
    selected = tv.selection.selected_rows
    return nil if !tv.model or selected.size <= 0
    
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
  
  @@editable_text_callbacks = {
    :datetime => {
      :value => proc{ |data|
        begin
          Datet.in(data[:value]).dbstr
        rescue ArgumentError
          raise "Invalid timestamp entered."
        end
      },
      :value_set => proc{ |data|
        Datet.in(data[:value]).out
      }
    },
    :time_as_sec => {
      :value => proc{ |data| Knj::Strings.human_time_str_to_secs(data[:value]) },
      :value_set => proc{ |data| Knj::Strings.secs_to_human_time_str(data[:value]) }
    },
    :int => {
      :value => proc{ |data| data[:value].to_i.to_s }
    },
    :human_number => {
      :value => proc{ |data| Knj::Locales.number_in(data[:value]) },
      :value_set => proc{ |data| Knj::Locales.number_out(data[:value], data[:col_data][:decimals]) }
    },
    :toggle_rev => {
      :value_set => lambda{|data|
        if data[:value]
          return false
        else
          return true
        end
      }
    }
  }
  
  def self.editable_text_renderers_to_model(args)
    args[:id_col] = 0 if !args.key?(:id_col)
    
    args[:cols].each do |col_no, col_data|
      col_data = {:col => col_data} if col_data.is_a?(Symbol)
      
      if col_data.key?(:type)
        if callbacks = @@editable_text_callbacks[col_data[:type]]
          col_data[:value_callback] = callbacks[:value] if callbacks.key?(:value)
          col_data[:value_set_callback] = callbacks[:value_set] if callbacks.key?(:value_set)
        else
          raise "Invalid type: '#{col_data[:type]}'."
        end
      end
      
      renderer = args[:renderers][col_no]
      raise "Could not find a renderer for column no. '#{col_no}'." if !renderer
      
      if args[:on_edit]
        renderer.signal_connect("editing-started") do |renderer, row_no, path|
          iter = args[:tv].model.get_iter(path)
          id = args[:tv].model.get_value(iter, args[:id_col])
          
          if id.to_i > 0
            model_obj = args[:ob].get(args[:model_class], id)
            args[:on_edit].call(:renderer => renderer, :row_no => row_no, :path => path, :args => args, :model => model_obj, :col_no => col_no, :col_data => col_data)
          end
        end
      end
      
      if args[:on_edit_done]
        renderer.signal_connect("editing-canceled") do |renderer|
          args[:on_edit_done].call(:renderer => renderer, :done_mode => :canceled, :args => args, :col_no => col_no, :col_data => col_data)
        end
      end
      
      if col_data[:on_edit]
        renderer.signal_connect("editing-started") do |renderer, row_no, path|
          iter = args[:tv].model.get_iter(path)
          id = args[:tv].model.get_value(iter, args[:id_col])
          model_obj = args[:ob].get(args[:model_class], id)
          
          col_data[:on_edit].call(:renderer => renderer, :row_no => row_no, :path => path, :iter => iter, :args => args, :model => model_obj, :col_no => col_no, :col_data => col_data)
        end
      end
      
      if renderer.is_a?(Gtk::CellRendererText)
        renderer.editable = true
        renderer.signal_connect("edited") do |renderer, row_no, value|
          iter = args[:tv].model.get_iter(row_no)
          id = args[:tv].model.get_value(iter, args[:id_col])
          
          if id.to_i > 0
            model_obj = args[:ob].get(args[:model_class], id)
            cancel = false
            callback_hash = {:args => args, :value => value, :model => model_obj, :col_no => col_no, :col_data => col_data}
            
            if args[:on_edit_done]
              args[:on_edit_done].call(:renderer => renderer, :row_no => row_no, :done_mode => :canceled, :args => args, :model => model_obj, :col_no => col_no, :col_data => col_data)
            end
            
            if col_data[:value_callback]
              begin
                value = col_data[:value_callback].call(callback_hash)
                callback_hash[:value] = value
              rescue => e
                Knj::Gtk2.msgbox(e.message, "warning")
                cancel = true
              end
            end
            
            if !cancel
              begin
                args[:change_before].call(callback_hash) if args[:change_before]
              rescue => e
                cancel = true
                Knj::Gtk2.msgbox(e.message, "warning")
              end
              
              if !cancel
                begin
                  model_obj[col_data[:col]] = value
                  value = col_data[:value_set_callback].call(callback_hash) if col_data.key?(:value_set_callback)
                  iter[col_no] = value
                rescue => e
                  Knj::Gtk2.msgbox(e.message, "warning")
                ensure
                  args[:change_after].call(callback_hash) if args[:change_after]
                end
              end
            end
          end
        end
      elsif renderer.is_a?(Gtk::CellRendererToggle)
        renderer.activatable = true
        renderer.signal_connect("toggled") do |renderer, path|
          iter = args[:tv].model.get_iter(path)
          id = args[:tv].model.get_value(iter, 0)
          model_obj = args[:ob].get(args[:model_class], id) if id.to_i > 0
          
          if model_obj and col_data[:col]
            if model_obj[col_data[:col]].to_i == 1
              value = false
              value_i = 0
            else
              value = true
              value_i = 1
            end
          else
            if iter[col_no] == 0
              value = true
              value_i = 1
            else
              value = false
              value_i = 0
            end
          end
          
          callback_hash = {:args => args, :value => value, :model => model_obj, :col_no => col_no, :col_data => col_data}
          
          if col_data[:value_callback]
            begin
              value = col_data[:value_callback].call(callback_hash)
              callback_hash[:value] = value
            rescue => e
              Knj::Gtk2.msgbox(e.message, "warning")
              cancel = true
            end
          end
          
          if value
            value_i = 1
          else
            value_i = 0
          end
          
          callback_hash[:value] = value
          
          if !cancel
            args[:change_before].call(callback_hash) if args[:change_before]
            begin
              model_obj[col_data[:col]] = value_i if model_obj and col_data[:col]
              
              if col_data.key?(:value_set_callback)
                value = col_data[:value_set_callback].call(callback_hash)
                
                if value
                  value_i = 1
                else
                  value_i = 0
                end
              end
              
              iter[col_no] = value_i
            ensure
              args[:change_after].call(:args => args) if args[:change_after]
            end
          end
        end
      else
        raise "Invalid cellrenderer: '#{renderer.class.name}'."
      end
    end
  end
end

#Shortcuts on the actual treeview-objects.
class Gtk::TreeView
  #Shortcut to do Knj::Gtk2::Tv.sel(treeview)
  def sel
    return Knj::Gtk2::Tv.sel(self)
  end
  
  #Shortcut to do Knj::Gtk2.append(treeview, [data1, data2])
  def append(data)
    return Knj::Gtk2::Tv.append(self, data)
  end
  
  #Shortcut to do Knj::Gtk2.init(treeview, columns_array)
  def init(cols)
    return Knj::Gtk2::Tv.init(self, cols)
  end
end