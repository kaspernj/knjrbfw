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