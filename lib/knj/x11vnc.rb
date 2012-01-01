class Knj::X11VNC
  def initialize(args = {})
    @args = ArrayExt.hash_sym(args)
    @open = true
    
    cmd = "x11vnc -q"
    cmd << " -shared" if @args[:shared] or !@args.key?(:shared)
    cmd << " -forever" if @args[:forever] or !@args.key?(:forever)
    cmd << " -rfbport #{@args[:port]}" if @args[:port]
    cmd << " -nolookup" if @args[:nolookup] or !@args.key?(:nolookup)
    
    print cmd + "\n"
    
    @thread = Knj::Thread.new do
      IO.popen(cmd) do |process|
        @pid = process.pid
        process.sync
        
        while  read = process.read
          break if read.length == 0
          #print read
        end
        
        @open = false
        @pid = nil
        @thread = nil
      end
    end
    
    Kernel.at_exit do
      self.close
    end
  end
  
  def open?
    return @open
  end
  
  def close
    return nil if !@thread
    
    Process.kill("HUP", @pid) if @pid
    @thread.exit if @thread
    @thread = nil
    @open = false
    @pid = nil
  end
end