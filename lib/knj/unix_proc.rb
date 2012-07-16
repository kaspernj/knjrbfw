#Requires the 'wref'-gem.
require "wref" if !Kernel.const_defined?(:Wref)

#This class handels various stuff regarding Unix-processes.
class Knj::Unix_proc
  attr_reader :data
  
  PROCS = Wref_map.new
  MUTEX = Mutex.new
  
  #Spawns a process if it doesnt already exist in the wrap-map.
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
  
  #Returns an array with (or yields if block given) Unix_proc. Hash-arguments as 'grep'.
  def self.list(args = {})
    cmdstr = "ps aux"
    grepstr = ""
    
    if args["grep"]
      grepstr = "grep #{args["grep"]}" #used for ignoring the grep-process later.
      cmdstr << " | grep #{Knj::Strings.unixsafe(args["grep"])}"
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
  
  #Returns the "Knj::Unix_proc" for the current process.
  def self.find_self
    procs = Knj::Unix_proc.list("ignore_self" => false)
    pid_find = Process.pid
    
    proc_find = false
    procs.each do |proc_ele|
      if proc_ele["pid"].to_i == pid_find.to_i
        proc_find = proc_ele
        break
      end
    end
    
    return proc_find
  end
  
  #Return true if the given PID is running.
  def self.pid_running?(pid)
    begin
      Process.getpgid(pid)
      return true
    rescue Errno::ESRCH
      return false
    end
  end
  
  #Initializes various data for a Unix_proc-object. This should not be called manually but through "Unix_proc.list".
  def initialize(data)
    @data = data
  end
  
  #Updates the data. This should not be called manually, but is exposed because of various code in "Unix_proc.list".
  def update_data(data)
    @data = data
  end
  
  #Returns the PID of the process.
  def pid
    return @data["pid"].to_i
  end
  
  #Returns a key from the data or raises an error.
  def [](key)
    raise "No such data: #{key}" if !@data.key?(key)
    return @data[key]
  end
  
  #Kills the process.
  def kill
    Process.kill("TERM", @data["pid"].to_i)
  end
  
  #Kills the process with 9.
  def kill!
    Process.kill(9, @data["pid"].to_i)
  end
  
  #Tries to kill the process gently, waits a couple of secs to check if the process is actually dead, then sends -9 kill signals.
  def kill_ensure(args = {})
    begin
      self.kill
      sleep 0.1
      return nil if !self.alive?
      
      args[:sleep] = 2 if !args.key(:sleep)
      
      0.upto(5) do
        sleep args[:sleep]
        self.kill!
        sleep 0.1
        return nil if !self.alive?
      end
      
      raise "Could not kill the process."
    rescue Errno::ESRCH
      return nil
    end
  end
  
  #Returns true if the process is still alive.
  def alive?
    return Knj::Unix_proc.pid_running?(@data["pid"].to_i)
  end
end