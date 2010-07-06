Gtk.events << ["TreeView", "row_activated", org.gnome.gtk.TreeView::RowActivated, :onRowActivated, nil]

class Gtk::TreeView
	def set_model(newmodel)
		@knj_model = newmodel
		@ob.model = newmodel.ob
		newmodel.tv = self
		
		$knj_jruby_gtk_last_treeview = self
	end
	
	alias :model= :set_model
	
	def append_column(column)
		#do nothing - the Java mode should already have done this.
	end
	
	def model
		return @knj_model
	end
	
	def columns
		return TreeViewColumns.new(self)
	end
end

class TreeViewColumns < Array
	def initialize(treeview)
		@treeview = treeview
		@treeview.ob.columns.each do |column|
			Gtk.takeob = column
			self << Gtk::TreeViewColumn.new(nil, nil)
		end
	end
end

class Gtk::TreeViewColumn
	def initialize(title, renderer, last_args = {})
		@treeview = $knj_jruby_gtk_last_treeview
		
		if Gtk.takeob
			@ob = Gtk.takeob
			Gtk.takeob = nil
		else
			@ob = @treeview.ob.append_column
			@ob.title = title
			$knj_jruby_gtk_last_treeview_column = self
			renderer.init(self)
			colstring = @treeview.model.dcol[@treeview.columns.length - 1]
			renderer.text = colstring
		end
	end
	
	def set_visible(newval)
		@treeview.remove_column(@ob)
	end
	
	alias visible= set_visible
end

class Gtk::TreeIter
	def []=(key, value)
		dcol = @knj_model.dcol[key]
		@knj_model.ob.set_value(@ob, dcol, value)
	end
	
	def [](key)
		tv = @knj_model.tv
		selected = tv.ob.get_selection.get_selected_rows
		
		iter = @knj_model.ob.get_iter(selected[0])
		dcol = @knj_model.dcol[key]
		
		return @knj_model.ob.get_value(iter, dcol)
	end
	
	def model=(newmodel)
		@knj_model = newmodel
	end
end