Gtk.events << ["Dialog", "response", org.gnome.gtk.Dialog::Response, :onResponse, nil]

class Gtk::Dialog
	RESPONSE_OK = org.gnome.gtk.ResponseType::OK
	RESPONSE_YES = org.gnome.gtk.ResponseType::YES
	RESPONSE_NO = org.gnome.gtk.ResponseType::NO
	RESPONSE_CANCEL = org.gnome.gtk.ResponseType::CANCEL
	RESPONSE_CLOSE = org.gnome.gtk.ResponseType::CLOSE
	RESPONSE_DELETE_EVENT = org.gnome.gtk.ResponseType::DELETE_EVENT
	MODAL = true
	
	def initialize(title = nil, win_parent = nil, modal = nil, *buttons)
		if Gtk.takeob
			@ob = Gtk.takeob
			Gtk.takeob = nil
		else
			@ob = Gtk.evalob("org.gnome.gtk.Dialog").new(title, win_parent, modal)
			
			buttons.each do |button|
				self.add_button(button[0], button[1])
			end
			
			self.signal_connect("response") do
				self.destroy
			end
		end
	end
	
	def vbox
		return self
	end
	
	def has_separator=(newval)
		# FIXME: No way to do this in Java-GTK?
	end
	
	def destroy
		if @ob
			@ob.hide
		end
		
		@ob = nil
	end
end