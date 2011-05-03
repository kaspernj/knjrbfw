class Knj::Fs
	def initialize(args = {})
		@args = args
	end
	
	def spawn_driver
		file_path = "#{Knj::Php.realpath("#{File.dirname(__FILE__)}/drivers")}/#{@args[:driver]}.rb"
		raise "Driver does not exist: #{@args[:driver]}" if !File.exists(file_path)
		require file_path
		
		class_name = Knj::Php.ucwords(@args[:driver])
		@driver = self.class.const_get(class_name).new(:fs => self, :args => @args)
	end
end

class Knj::Fs::File
	def initialize
		
	end
end