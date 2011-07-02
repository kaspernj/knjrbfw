require "gdk-sharp, Version=2.12.0.0, Culture=neutral, PublicKeyToken=35e10195dab3c99f"
require "gtk-sharp, Version=2.12.0.0, Culture=neutral, PublicKeyToken=35e10195dab3c99f"
require "glade-sharp, Version=2.12.0.0, Culture=neutral, PublicKeyToken=35e10195dab3c99f"


#Hack Gtk
RealGtk = Gtk
RealGtk::Application.init

Gtk = Module.new do
	@all = {
		"Gtk" => [
			"Button", "CellRendererText", "ComboBox", "Dialog", "Entry", "Label", "ListStore", "Window", "ProgressBar",
			"VBox", "HBox", "Image", "IconSize", "StatusIcon", "Menu", "MenuItem", "Builder", "CheckButton",
			"FileChooserButton", "TreeView", "TreeViewColumn", "TreeSelection", "TreePath"
		],
		"Gdk" => [
			"Pixbuf", "Event", "EventButton"
		]
	}
	@events = {"Gtk" => {}}
	
	def self.all; return @all; end;
	def self.events; return @events; end
	
	def self.main
		RealGtk::Application.run
	end
	
	def self.main_quit
		RealGtk::Application.quit
	end
	
	def self.takeob=(newob)
		@takeob = newob
	end
	
	def self.takeob
		return @takeob
	end
end


#Hack Gdk
RealGdk = Module.const_get("Gdk")
Gdk = Module.new
module Gdk
	#nothing here yet.
end



Gtk.all.each do |parentclass, classes|
	classes.each do |classname|
		Kernel.const_get(parentclass).const_set(classname, Class.new do
				attr_reader :ob
				attr_writer :ob
				
				def initialize(*paras)
					if Gtk.takeob
						@ob = Gtk.takeob
						if !@ob
							raise "Gtk.takeob was not set correctly: " + @ob.class.to_s
						end
						
						print "Spawning '#{self.class.to_s}' from default takeob.\n"
						
						Gtk.takeob = nil
					else
						splitted = self.class.to_s.split("::")
						realclass = "Real#{splitted.first}"
						classob = Kernel.const_get(realclass).const_get(splitted.last)
						
						if !classob
							raise "Class does not exist: " + realclass + "::" + splitted.last
						end
						
						print "Spawning '#{self.class.to_s}' from default constructor.\n"
						
						@ob = classob.new(*paras)
						
						if !@ob
							raise "Object was not spawned: #{self.class.to_s}, #{@ob.class.to_s}, #{realclass}::#{splitted.last}"
						end
					end
				end
				
				def signal_connect(signal, &block)
					classname = self.class.to_s.split("::")
					
					if Gtk.events[classname[0]] and Gtk.events[classname[0]][classname[1]] and Gtk.events[classname[0]][classname[1]][signal]
						ironevent = Gtk.events[classname[0]][classname[1]][signal]
					end
					
					if !ironevent
						raise "No iron-event '#{signal}' for '#{self.class.to_s}'"
					end
					
					print "Connected signal '#{signal}' to '#{self.class.to_s}'\n"
					
					if !@ob.respond_to?(ironevent)
						#puts @ob.methods.sort
						raise "RealGtk::" + classname[1] + " does not respond to: #{ironevent}."
					end
					
					@ob.send(ironevent) do |*args|
						print "Called signal '#{signal}' on '#{self.class.to_s}'\n"
						block.call
					end
				end
				
				def method_missing(*paras)
					newparas = []
					first = true
					paras.each do |para|
						if first
							first = false
						else
							splitted = para.class.to_s.split("::")
							
							if splitted.first == "Gtk"
								para = para.ob
							elsif splitted.first == "Gdk"
								para = para.ob
							end
							
							newparas << para
						end
					end
					
					#print "Respond to '#{@ob.class.to_s}' -> '#{paras[0].to_s}'\n"
					if @ob.respond_to?(paras[0].to_s)
						#print "Send '#{@ob.class.to_s}' -> '#{paras[0].to_s}'\n"
						return @ob.send(paras[0], *newparas)
					end
					
					#puts @ob.methods.sort
					raise "No such method on #{self.class.name}:  #{paras[0]}"
				end
			end
		)
	end
end

files = ["gladexml", "gtk_combobox", "gtk_cellrenderertext", "window", "vbox", "stock", "label", "image", "iconsize", "entry", "dialog", "button", "gtk_builder", "gdk_pixbuf", "gdk_event", "gdk_eventbutton", "gtk_filechooserbutton", "gtk_liststore", "gtk_statusicon", "gtk_menuitem", "gtk_menu", "gtk_treeiter", "gtk_treeview", "gtk_treeviewcolumn", "gtk_treeselection", "glib"]
files.each do |file|
	require File.dirname(__FILE__) + "/" + file
end