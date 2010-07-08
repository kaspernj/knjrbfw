class Gtk::ComboBox
	def pack_start(widget, val)
		@ob.PackStart(widget.ob, val)
		@ob.AddAttribute(widget.ob, "text", 0)
	end
end