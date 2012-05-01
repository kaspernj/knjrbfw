class Knj::Kvm
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

class Knj::Kvm::Machine
  def initialize(args)
    @args = args
  end
  
  def pid
    return @args[:pid]
  end
  
  def name
    return @args[:name]
  end
  
  def mac
    raise "No MAC-address has been registered for this machine." if !@args.key?(:mac)
    return @args[:mac]
  end
  
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