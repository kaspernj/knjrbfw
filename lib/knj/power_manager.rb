class Knj::Power_manager
  def initialize(args = {})
    @args = args
    
    if !File.exists?("/proc/acpi/ac_adapter")
      raise "Could not find the proc-acpi folder."
    end
    
    Dir.new("/proc/acpi/ac_adapter").each do |file|
      next if file == "." or file == ".."
      fn = "/proc/acpi/ac_adapter/#{file}"
      
      if File.directory?(fn)
        @ac_folder = Knj::Php.realpath(fn)
        break
      end
    end
    
    raise "Could not register ac-folder." if !@ac_folder
  end
  
  def state
    cont = File.read("#{@ac_folder}/state")
    
    if match = cont.match(/state:\s*(.+)\s*/)
      return match[1]
    end
    
    raise "Could not figure out state."
  end
end