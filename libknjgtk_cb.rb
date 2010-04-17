def gtk_cb_init(paras)
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

def gtk_cb_getsel(cb)
	return {
		"active" => cb.active,
		"text" => cb.active_iter[0]
	}
end

class Gtk::ComboBox
	def init(items)
		paras = {
			"cb" => self,
			"items" => items
		}
		
		return gtk_cb_init(paras)
	end
	
	def sel
		return gtk_cb_getsel(self)
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