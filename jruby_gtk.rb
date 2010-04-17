require "java"
require "java/gtk.jar"

import org.gnome.glade.Glade
import org.gnome.gtk.Gtk

def GladeAutoConnect(in_filename, window, in_object)
	require "xmlsimple.rb"
	contents = File.read(in_filename)
	data = XmlSimple.xml_in(contents)
	glade = Glade::parse(in_filename, window)
	GladeAutoConnect_item(glade, in_object, data)
	
	return glade
end

def GladeAutoConnect_item(in_glade, in_object, data)
	data.each do |item|
		if (item[0] == "widget")
			if (item[1][0]["signal"])
				tha_class = item[1][0]["class"]
				tha_id = item[1][0]["id"]
				func_name = item[1][0]["signal"][0]["handler"]
				name = item[1][0]["signal"][0]["name"]
				object = in_glade.getWidget(tha_id)
				
				if (tha_class == "GtkButton" && name == "clicked")
					import org.gnome.gtk.Button
					fastConnect(object, "Button::Clicked", "onClicked", [in_object, func_name], "nil")
				elsif(tha_class == "GtkWindow" && name == "destroy")
					import org.gnome.gtk.Window
					fastConnect(object, "Window::DeleteEvent", "onDeleteEvent", [in_object, func_name], "false")
				elsif(tha_class == "GtkTreeView" && name == "key_press_event")
					import org.gnome.gtk.Widget
					fastConnect(object, "Widget::KeyPressEvent", "onKeyPressEvent", [in_object, func_name], "false")
				elsif((tha_class == "GtkImageMenuItem" || tha_class == "GtkMenuItem") && name == "activate")
					import org.gnome.gtk.MenuItem
					fastConnect(object, "MenuItem::Activate", "onActivate", [in_object, func_name], "nil")
				elsif(tha_class == "GtkTreeView" && name == "columns_changed")
					import org.gnome.gtk.TreeView
					import org.gnome.gtk.TreeSelection
					fastConnect(object.getSelection, "TreeSelection::Changed", "onChanged", [in_object, func_name], "nil")
				else
					print "Unknown class and event: ", tha_class, " and ", name, "\n"
				end
			end
		end
		
		if (item.class.to_s == "Array"|| item.class.to_s == "Hash")
			GladeAutoConnect_item(in_glade, in_object, item)
		end
	end
end

def fastConnect(in_object, in_eventstring, in_funcname, in_callback, defreturn)
	classname_part = in_eventstring.gsub(":", "")
	classname_string = "KnjGtkEvent_" + classname_part
	
	evalstring = "
		class " + classname_string + "
			include " + in_eventstring + "
			
			def self.spawn(in_object, in_callback)
				mygtkevent = " + classname_string + ".new
				mygtkevent.setOpts(in_object, in_callback)
				in_object.connect(mygtkevent)
			end
			
			def setOpts(in_object, in_callback)
				@object = in_object
				@callback = in_callback
			end
			
			def " + in_funcname + "(*args)
				tha_return = @callback[0].send(@callback[1], args)
				
				if (tha_return == nil)
					return " + defreturn + "
				end
				
				return tha_return
			end
		end
		
		" + classname_string + "::spawn(in_object, in_callback)
	"
	eval(evalstring)
end

def gtk_tv_init(tv, columns)
	dcol = org.gnome.gtk.DataColumn[columns.length].new
	dcol_arr = []
	count = 0
	columns.each do |col_name|
		colstring = org.gnome.gtk.DataColumnString.new
		dcol[count] = colstring
		dcol_arr[count] = colstring
		count += 1
	end
	
	list_store = org.gnome.gtk.ListStore.new(dcol)
	tv.setModel(list_store)
	
	count = 0
	colobs = []
	columns.each do |col_title|
		col = tv.appendColumn
		col.setTitle(col_title.to_s)
		col.setResizable(true)
		col.setReorderable(true)
		
		renderer = org.gnome.gtk.CellRendererText.new(col)
		renderer.setText(dcol[count])
		
		colobs[count] = col
		count += 1
	end
	
	return {
		"treeview" => tv,
		"model" => list_store,
		"dcols" => dcol_arr,
		"colobs" => colobs
	}
end

def gtk_tv_append(tvident, arr)
	model = tvident["model"]
	iter = model.appendRow
	
	count = 0
	arr.each do |value|
		model.setValue(iter, tvident["dcols"][count], value)
		count += 1
	end
end

def gtk_tv_getsel(tv)
	if (!tv || !tv["treeview"] || !tv["treeview"].getSelection)
		return nil
	end
	
	selected = tv["treeview"].getSelection.getSelectedRows
	
	if (selected.size <= 0)
		return nil
	end
	
	iter = tv["model"].getIter(selected[0])
	returnval = []
	
	count = 0
	tv["dcols"].each do |column|
		returnval[count] = tv["model"].getValue(iter, column)
		count += 1
	end
	
	return returnval
end