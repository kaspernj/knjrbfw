class Knj::Fs
  @drivers = []
  drivers_path = Php4r.realpath("#{File.dirname(__FILE__)}/drivers")
  Dir.new(drivers_path).each do |file|
    fn = "#{drivers_path}/#{file}"
    next if file == "." or file == ".." or File.directory?(fn)
    
    class_name = Php4r.ucwords(file.slice(0..-4)).to_sym
    print "Classname: #{class_name}\n"
    autoload class_name, fn
    
    @drivers << {
      :name => file.slice(0..-4),
      :args => const_get(class_name).args
    }
  end
  
  def self.drivers
    return @drivers
  end
  
  def initialize(args = {})
    @args = args
  end
  
  def spawn_driver
    class_name = Php4r.ucwords(@args[:driver])
    @driver = self.class.const_get(class_name).new(:fs => self, :args => @args)
  end
end

class Knj::Fs::File
  def initialize
    
  end
end