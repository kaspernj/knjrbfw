class Knj::Event_filemod
  attr_reader :args
  
  def initialize(args, &block)
    @args = args
    @run = true
    @mutex = Mutex.new
    
    @args[:wait] = 1 if !@args.key?(:wait)
    
    @mtimes = {}
    args[:paths].each do |path|
      @mtimes[path] = File.mtime(path)
    end
    
    Knj::Thread.new do
      while @run do
        break if !@args or !@args[:paths] or @args[:paths].empty?
        
        @mutex.synchronize do
          @args[:paths].each do |path|
            changed = false
            
            if @mtimes and !@mtimes.key?(path) and @mtimes.is_a?(Hash)
              @mtimes[path] = File.mtime(path)
            end
            
            begin
              newdate = File.mtime(path)
            rescue Errno::ENOENT
              #file does not exist.
              changed = true
            end
            
            if !changed and newdate and @mtimes and newdate > @mtimes[path]
              changed = true
            end
            
            if changed
              block.call(self, path)
              @args[:paths].delete(path) if @args and @args[:break_when_changed]
            end
          end
          
          sleep @args[:wait] if @args and @run
        end
      end
    end
  end
  
  def destroy
    @mtimes = {}
    @run = false
    @args = nil
  end
  
  def add_path(fpath)
    @args[:paths] << fpath
  end
end