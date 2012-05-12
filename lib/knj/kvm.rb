#This class and subclasses holds various functionality to view status for Kvm-instances.
class Knj::Kvm
  #Lists all running Kvm-instances on this machine.
  #===Examples
  # Knj::Kvm.list do |kvm|
  #   print kvm.pid
  # end
  def self.list
    list = []
    
    Knj::Unix_proc.list("grep" => "kvm") do |proc_obj|
      next if !proc_obj["cmd"].match(/^\/usr\/bin\/kvm\s+/)
      
      args = {
        :pid => proc_obj["pid"]
      }
      
      if mac_match = proc_obj["cmd"].match(/mac=(.+?)(,|\s+|$)/)
        args[:mac] = mac_match[1]
      end
      
      if name_match = proc_obj["cmd"].match(/\-name\s+(.+?)(,|\s+|$)/)
        args[:name] = name_match[1]
      end
      
      if args.length > 0 and args[:name].to_s.length > 0
        machine = Knj::Kvm::Machine.new(args)
        if block_given?
          yield(machine)
        else
          list << machine
        end
      end
    end
    
    if block_given?
      return nil
    else
      return list
    end
  end
end

#Describes each Kvm-instance.
class Knj::Kvm::Machine
  #Sets the data called from Knj::Kvm.list.
  def initialize(args)
    @args = args
  end
  
  #Returns the PID of the Kvm-instance.
  def pid
    return @args[:pid]
  end
  
  #Returns the name from the Kvm-instance.
  def name
    return @args[:name]
  end
  
  #Returns the MAC from a network interfaces on the Kvm-instance.
  def mac
    raise "No MAC-address has been registered for this machine." if !@args.key?(:mac)
    return @args[:mac]
  end
  
  #Returns what virtual interface the Kvm is using.
  #===Examples
  # kvm.iface #=> "vnet12"
  def iface
    if !@iface
      res = Knj::Os.shellcmd("ifconfig | grep \"#{self.mac[3, self.mac.length]}\"")
      
      if net_match = res.match(/^vnet(\d+)/)
        @iface = net_match[0]
      else
        raise "Could not figure out iface from '#{res}' for '#{self.name}'."
      end
    end
    
    return @iface
  end
  
  #Returns various data about the networking (how much have been sent and recieved).
  #===Examples
  # kvm.net_status #=> {:tx => 1024, :rx => 2048}
  def net_status
    res = Knj::Os.shellcmd("ifconfig \"#{self.iface}\"")
    
    ret = {}
    
    if tx_bytes_match = res.match(/TX\s*bytes:\s*(\d+)/)
      ret[:tx] = tx_bytes_match[1].to_i
    end
    
    if rx_bytes_match = res.match(/RX\s*bytes:\s*(\d+)/)
      ret[:rx] = rx_bytes_match[1].to_i
    end
    
    return ret
  end
  
  #Returns various data about how much disk IO the Kvm-instance have been using.
  #===Examples
  # kvm.io_status #=> {:read_bytes => 1024, :write_bytes => 2048}
  def io_status
    io_status = File.read("/proc/#{self.pid}/io")
    
    if !matches = io_status.scan(/^(.+): (\d+)$/)
      raise "Could not match IO-status from: '#{io_status}'."
    end
    
    ret = {}
    matches.each do |match|
      ret[match[0].to_sym] = match[1].to_i
    end
    
    return ret
  end
end