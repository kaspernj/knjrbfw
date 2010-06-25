require "java"
require "/usr/share/java/gtk.jar"

import org.gnome.gtk.Gtk
Gtk.init(nil)

class Gtk
	@all = ["Window", "HBox", "VBox", "Label", "Button"]
	@containers = ["Window", "HBox", "VBox"]
	@titles = ["Window", "Button", "Label"]
	
	@all.each do |classname|
		self.const_set(classname, Class.new do
				def ob; return @ob; end
				def ob=(ob); @ob = ob; end
				
				def initialize(spawn_object = true)
					if spawn_object
						@ob = eval("org.gnome.gtk." + classname).new
					end
				end
				
				def connect(event, &block)
					if !block_given?
						raise "No block was given."
					end
					
					constant = self.class.to_s.split("::")[3]
					defreturn = nil
					
					if constant == "Window" and event == "destroy"
						class_inc = org.gnome.gtk.Window::DeleteEvent
						funcname = :onDeleteEvent
						defreturn = false
					elsif constant == "Button" and event == "clicked"
						class_inc = org.gnome.gtk.Button::Clicked
						funcname = :onClicked
					else
						raise "No eventstring for class '" + constant + "' and event '" + event + "'"
					end
					
					eventclass = Class.new do
						include(class_inc)
					end
					eventclass.instance_eval do
						define_method funcname do |*args|
							#First argument is always the widget - make it a converted widget instead.
							cname = args[0].class.to_s.split("::")[2]
							widget = Gtk.const_get(cname).new(false)
							widget.ob = args[0]
							args[0] = widget
							
							ret = block.call(*args)
							
							if ret == nil
								return defreturn
							end
							
							return ret
						end
					end
					
					@ob.connect(eventclass.new)
				end
				
				def method_missing(*paras)
					newparas = []
					first = true
					paras.each do |para|
						if first
							first = false
						else
							newparas << para
						end
					end
					
					if @ob.respond_to?(paras[0])
						return @ob.send(paras[0], *newparas)
					end
				end
			end
		)
	end
	
	@titles.each do |classname|
		self.const_get(classname).class_eval do
			def initialize(newtitle = nil)
				classname =  self.class.to_s.split("::")[3]
				@ob = eval("org.gnome.gtk." + classname).new
				
				if newtitle
					if @ob.respond_to?("label=")
						@ob.label = newtitle
					elsif @ob.respond_to?("title=")
						@ob.title = newtitle
					else
						raise "Could not set title on element."
					end
				end
			end
		end
	end
	
	@containers.each do |classname|
		self.const_get(classname).class_eval do
			def add(widget)
				return @ob.add(widget.ob)
			end
		end
	end
end

class GladeXML
	def initialize(filename, &block)
		require "xmlsimple"
		
		cont = File.read(filename)
		data = XmlSimple.xml_in(cont)
		
		window_name = self.find_window(data)
		
		@glade = org.gnome.glade.Glade::parse(filename, window_name)
		
		if block_given?
			@block = block
			self.auto_connect(data)
		end
	end
	
	def auto_connect(data)
		data.each do |item|
			if item[0] == "widget"
				if item[1][0]["signal"]
					tha_class = item[1][0]["class"]
					tha_id = item[1][0]["id"]
					func_name = item[1][0]["signal"][0]["handler"]
					name = item[1][0]["signal"][0]["name"]
					
					method = @block.call(func_name)
					
					object = self.get_widget(tha_id)
					object.connect(name) do |*paras|
						#Convert arguments to fit the arity-count of the Proc-object (the block, the method or whatever you want to call it).
						newparas = []
						0.upto(method.arity - 1) do |number|
							if paras[number]
								newparas << paras[number]
							end
						end
						
						method.call(*newparas)
					end
				end
			end
			
			if item.is_a?(Array) or item.is_a?(Hash)
				self.auto_connect(item)
			end
		end
	end
	
	def find_window(data)
		data.each do |item|
			if item[0] == "widget"
				class_str = item[1][0]["class"]
				
				if class_str == "GtkWindow"
					return item[1][0]["id"]
				end
			elsif item.class.to_s == "Array"|| item.class.to_s == "Hash"
				ret = self.find_window(item)
				if ret
					return ret
				end
			end
		end
	end
	
	def get_widget(wname)
		widget = @glade.get_widget(wname)
		
		conv_widget = Gtk.const_get(widget.class.to_s.split("::")[2]).new(false)
		conv_widget.ob = widget
		
		return conv_widget
	end
	
	def [](wname)
		return self.get_widget(wname)
	end
end