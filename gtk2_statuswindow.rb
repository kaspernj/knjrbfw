module Knj
	module Gtk2
		class StatusWindow
			def initialize(opts)
				@opts = opts
				
				@window = Gtk::Window.new("Status")
				@window.modal = true
				@window.set_frame_dimensions(3, 3, 3, 3)
				
				if (opts["transient_for"])
					@window.transient_for = @opts["transient_for"]
				end
				
				@label = Gtk::Label.new("Loading...")
				@pbar = Gtk::ProgressBar.new
				
				@vbox = Gtk::VBox.new
				@vbox.spacing = 4
				@vbox.pack_start(@label, false, true)
				@vbox.pack_start(@pbar, false, true)
				
				@window.add(@vbox)
				
				@window.show_all
			end
			
			def label=(newlabel)
				@label.label = newlabel
			end
			
			def percent=(newperc)
				@pbar.fraction = newperc
			end
			
			def destroy
				@window.destroy
				@window = nil
				@vbox = nil
				@pbar = nil
				@label = nil
				@opts = nil
			end
		end
	end
end