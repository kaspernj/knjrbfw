require "Qt"
require "qtuitools"
require "knjrbfw/libqt_window.rb"

class QtLoader
	def window
		return @window
	end
	
	def loader
		return @loader
	end
	
	def object_connect
		return @object_connect
	end
	
	def widget(name)
		return @widgets[name]
	end
	
	def initialize(paras)
		@widgets = {}
		
		if (paras.class.to_s == "Hash")
			file_path = paras["file"]
			@object_connect = paras["object_connect"]
		elsif(paras.class.to_s == "String")
			file_path = paras
		elsif(paras.class.to_s == "Array")
			file_path = paras[0]
			@object_connect = paras[1]
		else
			raise "Unknown parameter"
		end
		
		file = Qt::File.new(file_path)
		file.open(Qt::File::ReadOnly)
		@loader = Qt::UiLoader.new
		@window = @loader.load(file, nil)
		file.close
		
		
		@window.findChildren(Qt::Object).each do |widget|
			object_name = widget.object_name.to_s
			
			if (object_name.length > 0)
				@widgets[object_name] = widget
				
				if (@object_connect)
					meta = widget.meta_object
					signals = {}
					0.upto(meta.methodCount - 1) do |count|
						method_info = meta.method(count)
						
						if (method_info.method_type == 1)
							method_name = method_info.signature.match(/^(.+)\(/)
							signals[method_name[1]] = method_info.signature
						end
					end
				end
				
				signals.each do |item|
					func_name = "on_" + object_name + "_" + item[0]
					if (@object_connect.respond_to?(func_name))
						params = item[1].sub(/[a-z]+(\(.*$)/, '\1')
						widget.connect(SIGNAL item[1]) do
							@object_connect.send(func_name)
						end
					end
				end
			end
		end
	end
end