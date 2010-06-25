require "java"
require "/usr/share/java/gtk.jar"

["Window", "Label", "Button"].each do |classname|
		self.const_get(classname).class_eval do
			def initialize(newtitle = nil)
				super()
				
				if newtitle
					if self.ob.respond_to?("label=")
						self.ob.label = newtitle
					elsif self.ob.respond_to?("title=")
						self.ob.title = newtitle
					else
						raise "Could not set title on element."
					end
				end
			end
		end
	end

self.constants.each do |constant|
		self.const_get(constant).class_eval do
			alias connect_old connect
			undef connect
			
			def connect(event, &block)
				constant = self.class.to_s.split("::")[2]
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
						ret = block.call(*args)
						
						if ret == nil
							return defreturn
						end
						
						return ret
					end
				end
				
				self.connect_old(eventclass.new)
			end
		end
	end

org.gnome.gtk.Gtk.init(nil)

class JRubyGtk
	def ob; return @ob; end
	
	def initialize(rbob, newob)
		@ob = newob
		
		@ob.public_methods.each do |methodname|
			if !rbob.respond_to?(methodname)
				rbob.class.instance_eval do
					define_method methodname.to_sym do |*paras|
						return @ob.send(methodname, *paras)
					end
				end
			end
		end
	end
end

class GladeXML
	def initialize(filename)
		
	end
end

class Gtk
	class WindowDeleteEvent
		def onDeleteEvent(*paras)
			print "hmm?\n"
			#yield(paras)
			
			return false
		end
	end
	
	def self.main
		org.gnome.gtk.Gtk.main
	end
	
	["Window", "Button", "Label", "CheckButton", "HBox", "VBox"].each do |name|
		self.const_set(name, Class.new(JRubyGtk) do |title|
				inherited(JRubyGtk)
				
				def initialize(title)
					evalstr = "org.gnome.gtk." + self.class.to_s.slice(5..-1) + ".new(title)"
					#print evalstr + "\n\n"
					
					@ob = eval(evalstr)
					super(self, @ob)
				end
				
				def connect(event)
					if !block_given?
						raise "No block given."
					else
						if event == "destroy"
							event = Gtk::WindowDeleteEvent.new
							event.onDeleteEvent
							
							print @ob.class.to_s + "\n"
							@ob.connect(event)
							
							print "Connected.\n"
						else
							raise "Unsupported event: " + event
						end
					end
				end
			end
		)
	end
	
	class Window
		def initialize(title = nil)
			@ob = org.gnome.gtk.Window.new
			super(self, @ob)
			
			if title
				@ob.setTitle(title)
			end
		end
		
		def add(ob)
			@ob.add(ob.ob)
		end
	end
end