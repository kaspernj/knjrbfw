require "gtk-sharp, Version=2.12.0.0, Culture=neutral, PublicKeyToken=35e10195dab3c99f"
require "glade-sharp, Version=2.12.0.0, Culture=neutral, PublicKeyToken=35e10195dab3c99f"

RealGtk = Gtk
RealGtk::Application.init

Gtk = Module.new do
	@all = {"Gtk" => ["Window", "Button", "Entry", "Label", "ProgressBar", "VBox", "HBox", "Dialog", "Image", "IconSize"]}
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

Gtk.all.each do |parentclass, classes|
	classes.each do |classname|
		Kernel.const_get(parentclass).const_set(classname, Class.new do
				attr_reader :ob
				attr_writer :ob
				
				def initialize
					if Gtk.takeob
						@ob = Gtk.takeob
						Gtk.takeob = nil
					else
						splitted = self.class.to_s.split("::")
						@ob = RealGtk.const_get(splitted.last).new
					end
					
					if !@ob
						raise "Object was not spawned: #{self.class.to_s}"
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
					
					if !@ob.respond_to?(ironevent)
						puts @ob.methods.sort
						raise "RealGtk::" + classname[1] + " does not respond to: #{ironevent}."
					end
					
					@ob.send(ironevent) do |sender, e|
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

files = ["gladexml", "window", "vbox", "stock", "label", "image", "iconsize", "entry", "dialog", "button"]
files.each do |file|
	require File.dirname(__FILE__) + "/" + file
end