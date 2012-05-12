require "wref"

#This class handels various stuff regarding Unix-processes.
class Knj::Unix_proc
  attr_reader :data
  
  PROCS = Wref_map.new
  MUTEX = Mutex.new
  
  def self.spawn(data)
    pid = data["pid"].to_i
    
    begin
      proc_ele = PROCS[pid]
      proc_ele.update_data(data)
    rescue Wref::Recycled
      proc_ele = Knj::Unix_proc.new(data)
      PROCS[pid] = proc_ele
    end
    
    return proc_ele
  end
  
  def self.list(args = {})
    cmdstr = "ps aux"
    grepstr = ""
    
    if args["grep"]
      grepstr = "grep #{Knj::Strings.unixsafe(args["grep"])}"
      cmdstr << " | #{grepstr}"
    end
    
    MUTEX.synchronize do
      ret = [] unless block_given?
      res = Knj::Os.shellcmd(cmdstr)
      
      res.scan(/^(\S+)\s+([0-9]+)\s+([0-9.]+)\s+([0-9.]+)\s+\S+\s+\S+\s+\S+\s+\S+\s+\S+\s+\S+ (.+)($|\n)/) do |match|
        pid = match[1]
        
        data = {
          "user" => match[0],
          "pid" => pid,
          "cpu_last" => match[2],
          "ram_last" => match[3],
          "cmd" => match[4],
          "app" => File.basename(match[4])
        }
        
        next if (!args.key?("ignore_self") or args["ignore_self"]) and match[1].to_i == $$.to_i
        next if grepstr.length > 0 and match[4].index(grepstr) != nil #dont return current process.
        
        if args.key?("pids")
          found = false
          args["pids"].each do |pid_given|
            if pid_given.to_s == pid.to_s
              found = true
              break
            end
          end
          
          next if !found
        end
        
        proc_obj = Knj::Unix_proc.spawn(data)
        
        if block_given?
          yield(proc_obj)
        else
          ret << proc_obj
        end
      end
      
      PROCS.clean
      
      if block_given?
        return nil
      else
        return ret
      end
    end
  end
  
  def self.find_self
    procs = Knj::Unix_proc.list("ignore_self" => false)
    pid_find = Process.pid
    
    proc_find = false
    procs.each do |proc_ele|
      if proc_ele["pid"].to_s == pid_find.to_s
        proc_find = proc_ele
        break
      end
    end
    
    return proc_find
  end
  
  def initialize(data)
    @data = data
  end
  
  def update_data(data)
    @data = data
  end
  
  def [](key)
    raise "No such data: #{key}" if !@data.key?(key)
    return @data[key]
  end
  
  def kill
    Process.kill(9, @data["pid"].to_i)
  end
end