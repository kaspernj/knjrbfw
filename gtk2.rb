module Knj
	module Gtk2
		autoload :Cb, "knj/gtk2_cb"
		autoload :Menu, "knj/gtk2_menu"
		autoload :StatusWindow, "knj/gtk2_statuswindow"
		autoload :Tv, "knj/gtk2_tv"
		
		def msgbox(paras, type = "warning", title = "Warning")
			if paras.is_a?(Array)
				msg = paras[0]
				title = paras[2]
				type = paras[1]
			elsif paras.is_a?(Hash)
				msg = paras["msg"]
				title = paras["title"]
				type = paras["type"]
			elsif paras.is_a?(String) or paras.is_a?(Integer)
				msg = paras
			else
				raise "Cant handle the parameters: " + paras.class.to_s
			end
			
			if !type
				type = "info"
			end
			
			if !title
				if type == "yesno"
					title = "Question"
				else
					title = "Message"
				end
			end
			
			if type == "yesno"
				button1 = [Gtk::Stock::YES, Gtk::Dialog::RESPONSE_YES]
				button2 = [Gtk::Stock::NO, Gtk::Dialog::RESPONSE_NO]
				
				image = Gtk::Image.new(Gtk::Stock::DIALOG_QUESTION, Gtk::IconSize::DIALOG)
			elsif type == "warning"
				button1 = [Gtk::Stock::OK, Gtk::Dialog::RESPONSE_OK]
				image = Gtk::Image.new(Gtk::Stock::DIALOG_WARNING, Gtk::IconSize::DIALOG)
			elsif type == "info"
				button1 = [Gtk::Stock::OK, Gtk::Dialog::RESPONSE_OK]
				image = Gtk::Image.new(Gtk::Stock::DIALOG_INFO, Gtk::IconSize::DIALOG)
			else
				raise "No such mode: " + type
			end
			
			box = Gtk::HBox.new
			
			if button1 && button2
				dialog = Gtk::Dialog.new(title, nil, Gtk::Dialog::MODAL, button1, button2)
			else
				dialog = Gtk::Dialog.new(title, nil, Gtk::Dialog::MODAL, button1)
			end
			
			if image
				box.pack_start(image)
			end
			
			if type == "warning" or type == "yesno" or type == "info"
				box.pack_start(Gtk::Label.new(msg))
			else
				raise "No such mode: " + type
			end
			
			box.spacing = 15
			dialog.border_width = 5
			dialog.vbox.add(box)
			dialog.has_separator = false
			dialog.show_all
			response = dialog.run
			dialog.destroy
			
			if response == Gtk::Dialog::RESPONSE_OK
				return "ok"
			elsif response == Gtk::Dialog::RESPONSE_YES
				return "yes"
			elsif response == Gtk::Dialog::RESPONSE_NO
				return "no"
			elsif response == Gtk::Dialog::RESPONSE_CANCEL
				return "cancel"
			elsif response == Gtk::Dialog::RESPONSE_CLOSE or response == Gtk::Dialog::RESPONSE_DELETE_EVENT
				return "close"
			else
				raise "Unknown response: " + response.to_s
			end
		end
		
		def self.translate(builderob)
			builderob.objects.each do |object|
				class_str = object.class.to_s
				
				if class_str == "Gtk::Label" or class_str == "Gtk::Button"
					object.label = GetText::gettext(object.label)
				elsif class_str == "Gtk::Window"
					object.title = GetText::gettext(object.title)
				end
			end
		end
		
		def form(paras)
			table = Gtk::Table.new(paras.length, 2)
			table.row_spacings = 4
			table.column_spacings = 4
			top = 0
			objects = {}
			
			paras.each do |item|
				if item["type"] == "text" or item["type"] == "password"
					label = Gtk::Label.new(item["title"])
					label.xalign = 0
					text = Gtk::Entry.new
					
					if item["type"] == "password"
						text.visibility = false
					end
					
					if item["default"]
						text.text = item["default"]
					end
					
					table.attach(label, 0, 1, top, top + 1, Gtk::FILL, Gtk::FILL)
					table.attach(text, 1, 2, top, top + 1, Gtk::EXPAND | Gtk::FILL, Gtk::SHRINK)
					
					objects[item["name"]] = {
						"type" => "text",
						"object" => text
					}
				elsif (item["type"] == "check")
					check = Gtk::CheckButton.new(item["title"])
					table.attach(check, 0, 2, top, top + 1, Gtk::EXPAND | Gtk::FILL, Gtk::SHRINK)
					
					objects[item["name"]] = {
						"type" => "check",
						"object" => check
					}
				end
				
				
				top += 1
			end
			
			return {
				"table" => table,
				"objects" => objects
			}
		end
		
		def form_setval(object, val)
			if object.is_a?(Gtk::Entry)
				object.text = val.to_s
			elsif object.is_a?(Gtk::CheckButton)
				if (val.to_s == "1")
					object.active = true
				else
					object.active = false
				end
			end
		end
		
		def form_getval(object)
			if object.is_a?(Gtk::Entry)
				return object.text
			elsif object.is_a?(Gtk::CheckButton)
				if (object.active?)
					return "1"
				else
					return "0"
				end
			end
		end
	end
end

module Gtk
	class Builder
		def translate
			return Knj::Gtk2::translate(self)
		end
	end
end