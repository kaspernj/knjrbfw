class Gtk::ListStore
	def initialize(*args)
		args_cons = []
		args.each do |col_name|
			args_cons << System::String.to_clr_type
		end
		
		@ob = RealGtk::ListStore.new(*args_cons)
	end
	
	def append
		Gtk.takeob = @ob.append
		retob = Gtk::TreeIter.new
		retob.liststore = self
		
		return retob
	end
end