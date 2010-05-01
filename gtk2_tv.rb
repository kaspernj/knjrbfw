module Knj
	module Gtk2
		module Tv
			def self.init(tv, columns)
				list_store = nil
				eval_string = "list_store = Gtk::ListStore.new("
				
				first = true
				columns.each do |pair|
					if (first == true)
						first = false
					else
						eval_string += ", "
					end
					
					eval_string += "String"
				end
				
				eval_string += ");"
				eval(eval_string)
				
				tv.set_model(list_store)
				
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
				data.each{ |value|
					iter[count] = value
					count += 1
				}
			end
			
			def self.sel(tv)
				selected = tv.selection.selected_rows
				
				if (!tv.model or selected.size <= 0)
					return nil
				end
				
				iter = tv.model.get_iter(selected[0])
				returnval = []
				columns = tv.columns
				
				count = 0
				columns.each{|column|
					returnval[count] = iter[count]
					count += 1
				}
				
				return returnval
			end
		end
	end
end

class Gtk::TreeView
	def sel
		return Knj::Gtk2::Tv::sel(self)
	end
	
	def append(data)
		return Knj::Gtk2::Tv::append(self, data)
	end
	
	def init(cols)
		return Knj::Gtk2::Tv::init(self, cols)
	end
end