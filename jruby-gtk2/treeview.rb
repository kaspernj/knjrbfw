module Gtk
	class TreeView
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
	end
	
	class TreeViewColumn
		def initialize(title, renderer, last_args = {})
			if $knj_jruby_gtk_takeob
				@ob = $knj_jruby_gtk_takeob
				$knj_jruby_gtk_takeob = nil
			else
				@ob = $knj_jruby_gtk_last_treeview.ob.append_column
				@ob.title = title
			end
			
			$knj_jruby_gtk_last_treeview_column = self
			renderer.init(self)
			colstring = $knj_jruby_gtk_last_liststore.dcol[$knj_jruby_gtk_last_treeview.columns.length - 1]
			renderer.text = colstring
		end
	end
	
	class TreeIter
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
end