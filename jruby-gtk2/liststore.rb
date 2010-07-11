class Gtk::ListStore
	def dcol; return @dcol; end
	def dcol_arr; return @dcol_arr; end
	def tv; return @knj_tv; end
	
	def initialize(*args)
		if Gtk.takeob
			@ob = Gtk.takeob
			Gtk.takeob = nil
		else
			splitted = self.class.to_s.split("::")
			classname =  splitted[splitted.length - 1]
			
			class_spawn = Gtk.evalob("org.gnome.gtk." + classname)
			if !class_spawn
				raise "Could not find class: " + classname
			end
			
			@dcol = org.gnome.gtk.DataColumn[args.length].new
			@dcol_arr = []
			count = 0
			args.each do |col_name|
				colstring = org.gnome.gtk.DataColumnString.new
				@dcol[count] = colstring
				@dcol_arr[count] = colstring
				count += 1
			end
			
			@ob = class_spawn.new(@dcol)
		end
		
		$knj_jruby_gtk_last_liststore = self
	end
	
	def append
		Gtk.takeob = @ob.appendRow
		iter = Gtk::TreeIter.new
		iter.model = self
		
		return iter
	end
	
	def tv=(newtv)
		@knj_tv = newtv
	end
	
	def get_iter(selection)
		iter = @ob.get_iter(selection)
		
		Gtk.takeob = iter
		retob = Gtk::TreeIter.new
		retob.model = self
		
		return retob
	end
end