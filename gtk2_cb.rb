module Knj
	module Gtk2
		module Cb
			def init(paras)
				ls = Gtk::ListStore.new(String, String)
				cr = Gtk::CellRendererText.new
				
				paras["items"].each do |string|
					iter = ls.append
					iter[0] = string
				end
				
				paras["cb"].pack_start(cr, true)
				paras["cb"].add_attribute(cr, "text", 0)
				paras["cb"].model = ls
			end
			
			def sel(cb)
				return {
					"active" => cb.active,
					"text" => cb.active_iter[0]
				}
			end
		end
	end
end

class Gtk::ComboBox
	def init(items)
		paras = {
			"cb" => self,
			"items" => items
		}
		
		return Knj::Gtk2::Cb::init(paras)
	end
	
	def sel
		return Knj::Gtk2::Cb::sel(self)
	end
	
	def sel=(textval)
		self.model.each do |model, path, iter|
			text = self.model.get_value(iter, 0)
			
			if (text == textval)
				self.active_iter = iter
				return nil
			end
		end
		
		raise "Could not find such a row: " + textval
	end
end