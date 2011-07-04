class Gtk::FileChooserButton
	def filename=(newfilename)
		@ob.set_filename(newfilename)
	end
end