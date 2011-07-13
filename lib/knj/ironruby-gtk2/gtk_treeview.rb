class Gtk::TreeView
	def selection
		if !@selection
			Gtk.takeob = @ob.selection
			@selection = Gtk::TreeSelection.new
		end
		
		return @selection
	end
	
	def model=(newmodel)
		@model = newmodel
		@ob.model = newmodel.ob
	end
	
	def model
		return @model
	end
end