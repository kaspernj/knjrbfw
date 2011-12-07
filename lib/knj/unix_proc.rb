class Knj::Unix_proc
  attr_reader :data
  @procs = {}
  
  def self.spawn(data)
    proc_ele = @procs[data["pid"]]
    
    if proc_ele
      proc_ele.update_data(data)
    else
      @procs[data["pid"]] = Knj::Unix_proc.new(data)
    end
    
    return @procs[data["pid"]]
  end
  
  def self.list(args = {})
    cmdstr = "ps aux"
    grepstr = ""
    
    if args["grep"]
      grepstr = "grep #{Knj::Strings.unixsafe(args["grep"])}"
      cmdstr += " | #{grepstr}"
    end
    
    ret = []
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
      next if args.key?("pids") and args["pids"].index(pid) == nil
      
      ret << Knj::Unix_proc.spawn(data)
    end
    
    return ret
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