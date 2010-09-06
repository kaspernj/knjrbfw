require "java"
require File.dirname(__FILE__) + "/gtk-4.0.jar"

org.gnome.gtk.Gtk.init(nil)

@all = {
	"Gtk" => ["Dialog", "Window", "HBox", "IconSize", "Image", "VBox", "Label", "Button", "ListStore", "TreeView", "TreeViewColumn",
					"CellRendererText", "DataColumnString", "TreeIter", "StatusIcon", "Entry", "ProgressBar",
					"Menu", "MenuItem", "CheckButton", "ComboBox", "FileChooserButton"
	],
	"Gdk" => ["Pixbuf", "Event", "EventButton"]
}
@containers = {
	"Gtk" => ["Window", "HBox", "VBox"]
}
@titles = {
	"Gtk" => ["Window", "Button", "Label"]
}
@constants = {
	"Gdk" => {
		"Event" => ["BUTTON_PRESS", org.gnome.gdk.EventType::BUTTON_PRESS]
	}
}

module Gtk
	@events = [
		["Button", "clicked", org.gnome.gtk.Button::Clicked, :onClicked, nil],
		["MenuItem", "activate", org.gnome.gtk.MenuItem::Activate, :onActivate, nil],
		["Entry", "activate", org.gnome.gtk.Entry::Activate, :onActivate, nil]
	]
	
	def self.events; return @events; end
	def self.takeob=(takeob); @takeob = takeob; end
	def self.takeob; return @takeob; end
	
	#Cache eval'ed objects to get it done faster.
	@evalobs = {
		"org.gnome.gtk.Button" => org.gnome.gtk.Button,
		"org.gnome.gtk.Dialog" => org.gnome.gtk.Dialog,
		"org.gnome.gtk.HBox" => org.gnome.gtk.HBox,
		"org.gnome.gtk.Image" => org.gnome.gtk.Image,
		"org.gnome.gtk.Label" => org.gnome.gtk.Label,
		"org.gnome.gtk.ListStore" => org.gnome.gtk.ListStore,
		"org.gnome.gtk.Window" => org.gnome.gtk.Window
	}
	def self.evalob(evalobstr)
		if !@evalobs.has_key?(evalobstr)
			print "Not statically written: #{evalobstr}\n"
			@evalobs[evalobstr] = eval(evalobstr)
		end
		
		return @evalobs[evalobstr]
	end
end

module Gdk; end

@all.each do |parentclass, classes|
	classes.each do |classname|
		Kernel.const_get(parentclass).const_set(classname, Class.new do
				def ob; return @ob; end
				def ob=(ob); @ob = ob; end
				
				def initialize(spawn_object = true)
					if Gtk.takeob
						@ob = Gtk.takeob
						Gtk.takeob = nil
					else
						splitted = self.class.to_s.split("::")
						javaname = "org.gnome." + splitted.first.downcase + "." + splitted.last
						
						begin
							@ob = Gtk.evalob(javaname).new
						rescue Exception => e
							print "Could not spawn object: #{javaname}\n"
							raise e
						end
					end
				end
				
				def signal_connect(event, &block)
					if !block_given?
						raise "No block was given."
					end
					
					splitted = self.class.to_s.split("::")
					constant = splitted.last
					defreturn = nil
					class_inc = nil
					funcname = nil
					defreturn = nil
					
					Gtk.events.each do |eventarr|
						if constant == eventarr[0] and event == eventarr[1]
							class_inc = eventarr[2]
							funcname = eventarr[3]
							defreturn = eventarr[4]
							break
						end
					end
					
					if !class_inc or !funcname
						raise "No event for class '#{constant}' and event '#{event}'"
					end
					
					eventclass = Class.new do
						include(class_inc)
					end
					eventclass.instance_eval do
						define_method funcname do |*args|
							#First argument is always the widget - make it a converted widget instead.
							cname = args[0].class.to_s.split("::")[2]
							
							begin
								Gtk.takeob = args[0]
								widget = Gtk.const_get(cname).new(false)
								widget.ob = args[0]
								args[0] = widget
							rescue Exception => e
								print "Could not spawn widget: #{cname}\n"
								raise e
							end
							
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
							splitted = para.class.to_s.split("::")
							if splitted.first == "Gtk"
								para = para.ob
							end
							
							newparas << para
						end
					end
					
					if @ob.respond_to?(paras[0])
						return @ob.send(paras[0], *newparas)
					end
					
					raise "No such method on #{self.class.name}:  #{paras[0]}"
				end
			end
		)
	end
end

@titles.each do |parentclass, classes|
	classes.each do |classname|
		Kernel.const_get(parentclass).const_get(classname).class_eval do
			def initialize(newtitle = nil)
				if Gtk.takeob
					@ob = Gtk.takeob
					Gtk.takeob = nil
				else
					splitted = self.class.to_s.split("::")
					@ob = Gtk.evalob("org.gnome.gtk." + splitted.last).new
				end
				
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
end

@containers.each do |parentclass, classes|
	classes.each do |classname|
		Kernel.const_get(parentclass).const_get(classname).class_eval do
			def add(widget)
				return @ob.add(widget.ob)
			end
			
			def pack_start(widget, arg1 = false, arg2 = false)
				return @ob.pack_start(widget.ob, arg1, arg2, 0)
			end
		end
	end
end

@constants.each do |parentclass, classes|
	classes.each do |classname, data|
		Kernel.const_get(parentclass).const_get(classname).const_set(data[0], data[1])
	end
end

module Gtk
	class CellRendererText
		def initialize
			if Gtk.takeob
				@ob = Gtk.takeob
				Gtk.takeob = nil
			end
		end
		
		def init(tcol)
			@ob = org.gnome.gtk.CellRendererText.new(tcol.ob)
		end
	end
	
	class VBox
		def initialize
			if Gtk.takeob
				@ob = Gtk.takeob
				Gtk.takeob = nil
			else
				splitted = self.class.to_s.split("::")
				javaname = "org.gnome." + splitted.first.downcase + "." + splitted.last
				@ob = Gtk.evalob(javaname).new(false, 0)
			end
		end
	end
	
	def self.main
		org.gnome.gtk.Gtk.main
	end
	
	def self.main_quit
		org.gnome.gtk.Gtk.main_quit
	end
end

module Gdk
	class Pixbuf
		def initialize(filename)
			@ob = org.gnome.gdk.Pixbuf.new(filename)
		end
	end
end

module GLib
	class Timeout
		def self.add(time, &block)
			Thread.new(time, block) do |time, block|
				begin
					sleep(time / 1000)
					block.call
				rescue Exception => e
					puts e.inspect
					puts e.backtrace
				end
			end
		end
	end
end

files = ["builder", "checkbutton", "combobox", "dialog", "eventbutton", "hbox", "iconsize", "image", "liststore", "gladexml", "menu", "progressbar", "statusicon", "stock", "treeview", "window"]
files.each do |file|
	require File.dirname(__FILE__) + "/" + file
end