class Gtk::ComboBox
	def pack_start(widget, arg1, arg2 = false)
		#widget is useually a Gtk::CellRendererText which is started by this way in Java GTK.
		@renderer = widget
		widget.init(self)
		
		if self.model
			widget.text = self.model.dcol[0]
			@renderer_set = true
		end
	end
	
	def add_attribute(arg1, arg2, arg3)
		#do nothing - this method does not exist on Java GTK's ComboBox.
	end
	
	def model=(newmodel)
		@model = newmodel
		@ob.model = newmodel.ob
		
		if !@renderer_set
			@renderer.text = self.model.dcol[0]
		end
	end
	
	def model
		return @model
	end
end