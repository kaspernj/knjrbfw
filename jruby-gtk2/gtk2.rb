require "java"
require "/usr/share/java/gtk.jar"

org.gnome.gtk.Gtk.init(nil)

@all = {
	"Gtk" => ["Window", "HBox", "VBox", "Label", "Button", "ListStore", "TreeView", "TreeViewColumn", "CellRendererText", "DataColumnString", "TreeIter", "StatusIcon"],
	"Gdk" => ["Pixbuf"]
}
@containers = {
	"Gtk" => ["Window", "HBox", "VBox"]
}
@titles = {
	"Gtk" => ["Window", "Button", "Label"]
}

module Gtk
	@events = [
		["Window", "destroy", org.gnome.gtk.Window::DeleteEvent, :onDeleteEvent, false],
		["Button", "clicked", org.gnome.gtk.Button::Clicked, :onClicked, nil]
	]
	def self.events; return @events; end
end

module Gdk; end

@all.each do |parentclass, classes|
	classes.each do |classname|
		Kernel.const_get(parentclass).const_set(classname, Class.new do
				def ob; return @ob; end
				def ob=(ob); @ob = ob; end
				
				def initialize(spawn_object = true)
					if $knj_jruby_gtk_takeob
						@ob = $knj_jruby_gtk_takeob
						$knj_jruby_gtk_takeob = nil
					else
						splitted = self.class.to_s.split("::")
						classname =  splitted[splitted.length - 1]
						javaname = "org.gnome." + splitted[0].downcase + "." + classname
						@ob = eval(javaname).new
					end
				end
				
				def connect(event, &block)
					if !block_given?
						raise "No block was given."
					end
					
					splitted = self.class.to_s.split("::")
					constant = splitted[splitted.length - 1]
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
end

@titles.each do |parentclass, classes|
	classes.each do |classname|
		Kernel.const_get(parentclass).const_get(classname).class_eval do
			def initialize(newtitle = nil)
				if $knj_jruby_gtk_takeob
					@ob = $knj_jruby_gtk_takeob
					$knj_jruby_gtk_takeob = nil
				else
					splitted = self.class.to_s.split("::")
					classname =  splitted[splitted.length - 1]
					@ob = eval("org.gnome.gtk." + classname).new
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
		end
	end
end

module Gtk
	class CellRendererText
		def initialize
			if $knj_jruby_gtk_takeob
				@ob = $knj_jruby_gtk_takeob
				$knj_jruby_gtk_takeob = nil
			end
		end
		
		def init(tcol)
			@ob = org.gnome.gtk.CellRendererText.new(tcol.ob)
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
			require "timeout"
			Timeout.timeout(time) do
				block.call
			end
		end
	end
end

require File.dirname(__FILE__) + "/treeview"
require File.dirname(__FILE__) + "/liststore"
require File.dirname(__FILE__) + "/statusicon"