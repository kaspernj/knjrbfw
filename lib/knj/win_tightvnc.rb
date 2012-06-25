class Knj::Win::TightVNC
  def initialize(args)
    @args = ArrayExt.hash_sym(args)
    
    @args[:port] = 5900 if !@args[:port]
    @args[:port_http] = 5800 if !@args[:http_port]
    
    raise "No path given." if !@args[:path]
    
    exefile = @args[:path] + "/WinVNC.exe"
    raise "#{exefile} was not found." if !File.exists?(exefile)
    
    @wmi = WIN32OLE.connect("winmgmts://")
    processes = @wmi.ExecQuery("SELECT * FROM win32_process")
    ended = false
    for process in processes do
      if process.Name == "WinVNC.exe"
        process.Terminate
        ended = true
      end
    end
    
    sleep 1 if ended
    
    #print Win::Registry.get(:cur_user, 'Software\ORL\WinVNC3', 'Password', :sz).unpack('H*')[0] + "\n"
    #print ["160e9d46f26586ca"].pack('H*').unpack('H*')[0] + "\n"
    #exit
    
    Win::Registry.set(:cur_user, 'Software\ORL\WinVNC3', [
      ["AutoPortSelect", 1, :dword],
      ["BlankScreen", 0, :dword],
      ["DontSetHooks", 0, :dword],
      ["DontUseDriver", 0, :dword],
      ["DriverDirectAccess", 1, :dword],
      ["EnableFileTransfers", 1, :dword],
      ["HTTPPortNumber", @args[:port_http], :dword],
      ["IdleTimeout", 0, :dword],
      ["InputsEnabled", 1, :dword],
      ["LocalInputsDisabled", 0, :dword],
      ["LocalInputsPriority", 0, :dword],
      ["LocalInputsPriorityTime", 3, :dword],
      ["LockSetting", 0, :dword],
      ["OnlyPollConsole", 1, :dword],
      ["OnlyPollOnEvent", 0, :dword],
      ["PollForeground", 1, :dword],
      ["PollFullScreen", 0, :dword],
      ["PollingCycle", 300, :dword],
      ["PollUnderCursor", 0, :dword],
      ["PollUnderCursor", @args[:port], :dword],
      ["QueryAccept", 0, :dword],
      ["QueryAllowNoPass", 0, :dword],
      ["QuerySetting", 2, :dword],
      ["QueryTimeout", 30, :dword],
      ["RemoveWallpaper", 0, :dword],
      ["SocketConnect", 1, :dword],
      ["Password", ["160e9d46f26586ca"].pack('H*'), :bin],
      ["PasswordViewOnly", ["160e9d46f26586ca"].pack('H*'), :bin]
    ])
    Win::Registry.set(:local_machine, 'Software\ORL\WinVNC3', [
      ["AllowLoopback", 1, :dword],
      ["LoopbackOnly", 0, :dword]
    ])
    #password is of this moment only 'kaspernj'.
    
    @wmi = WIN32OLE.connect("winmgmts://")
    processes = @wmi.ExecQuery("SELECT * FROM win32_process")
    ended = false
    for process in processes do
      if process.Name == "WinVNC.exe"
        process.Terminate
        ended = true
      end
    end
    
    sleep 1 if ended
    
    Knj::Thread.new do
      IO.popen(exefile) do |process|
        #nothing
      end
    end
    
    sleep 1
    
    @processes = @wmi.ExecQuery("SELECT * FROM win32_process")
    for process in @processes do
      if process.Name == "WinVNC.exe"
        @process = process
        break
      end
    end
    
    raise "Could not start WinVNC.exe." if !@process
    
    Kernel.at_exit do
      self.close
    end
  end
  
  def open?
    begin
      @process.GetOwner
      return true
    rescue => e
      return false
    end
  end
  
  def close
    return nil if !@process
    
    begin
      @process.Terminate
    rescue => e
      if e.class.to_s == "WIN32OLERuntimeError" and e.message.index("Terminate") != nil
        #do nothing.
      else
        raise e
      end
    end
    
    @process = nil
    @args = nil
    @wmi = nil
    @processes = nil
  end
end