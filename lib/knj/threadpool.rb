class Knj::Threadpool
  def self.worker_data
    raise "This thread is not running via the threadpool." if !Thread.current[:knj_threadpool]
    return Thread.current[:knj_threadpool]
  end
  
  attr_reader :workers, :blocks, :mutex, :args, :events
  
  def initialize(args = {})
    @args = args
    @args[:sleep] = 0.2 if !@args.key?(:sleep)
    
    raise "Invalid number of threads: '#{@args[:threads]}'." if !@args[:threads] or @args[:threads].to_i <= 0
    
    @workers = []
    @blocks = []
    @mutex = Mutex.new
    @events = Knj::Event_handler.new
    @events.add_event(:name => :on_error)
    
    self.start
  end
  
  def start
    @mutex.synchronize do
      if !@running
        @workers.length.upto(@args[:threads]) do |count|
          @workers << Knj::Threadpool::Worker.new(:threadpool => self, :id => count)
        end
        
        @running = true
      end
    end
  end
  
  def stop
    if @running
      @workers.each do |worker|
        if !worker.running
          worker.kill
          @workers.delete(worker)
        end
      end
      
      @running = false
    end
  end
  
  def run(*args, &block)
    raise "No block given." if !block_given?
    blockdata = {:block => block, :result => nil, :running => false, :runned => false, :args => args}
    @blocks << blockdata
    
    loop do
      sleep @args[:sleep]
      
      if blockdata[:runned]
        begin
          res = blockdata[:result]
          raise blockdata[:error] if blockdata.key?(:error)
        ensure
          @mutex.synchronize do
            blockdata.clear
            @blocks.delete(blockdata)
          end
        end
        
        return res
      end
    end
  end
  
  def run_async(*args, &block)
    raise "No block given." if !block_given?
    
    @mutex.synchronize do
      blockdata = {:block => block, :running => false, :runned => false, :args => args}
      @blocks << blockdata
      return blockdata
    end
  end
  
  def get_block
    return false if !@running
    
    @mutex.synchronize do
      @blocks.each do |blockdata|
        if blockdata and !blockdata[:running] and !blockdata[:runned]
          blockdata[:running] = true
          return blockdata
        end
      end
      
      return false
    end
  end
end

class Knj::Threadpool::Worker
  attr_reader :running
  
  def initialize(args)
    @args = args
    @tp = @args[:threadpool]
    @mutex_tp = @tp.mutex
    @sleep = @tp.args[:sleep]
    @running = false
    self.spawn_thread
  end
  
  #Starts the workers thread.
  def spawn_thread
    @thread = Knj::Thread.new do
      loop do
        if !@blockdata
          sleep @sleep
          @blockdata = @tp.get_block if !@blockdata
        end
        
        next if !@blockdata
        
        res = nil
        raise "No block in blockdata?" if !@blockdata[:block]
        @blockdata[:worker] = self
        Thread.current[:knj_threadpool] = {
          :worker => self,
          :blockdata => @blockdata
        }
        
        begin
          if @blockdata.key?(:result)
            begin
              @running = true
              res = @blockdata[:block].call(*@blockdata[:args])
            rescue Exception => e
              @mutex_tp.synchronize do
                @blockdata[:error] = e
              end
            ensure
              @running = false
              
              @mutex_tp.synchronize do
                @blockdata[:result] = res
                @blockdata[:runned] = true
                @blockdata[:running] = false
              end
              
              #Try to avoid slowdown of sleep by checking if there is a new block right away.
              @blockdata = @tp.get_block
            end
          else
            begin
              @blockdata[:block].call(*@blockdata[:args])
            rescue Exception => e
              if @tp.events.connected?(:on_error)
                @tp.events.call(:on_error, e)
              else
                STDOUT.print Knj::Errors.error_str(e)
              end
            ensure
              @mutex_tp.synchronize do
                @blockdata.clear if @blockdata
                @tp.blocks.delete(@blockdata)
              end
              
              #Try to avoid slowdown of sleep by checking if there is a new block right away.
              @blockdata = @tp.get_block
            end
          end
        ensure
          Thread.current[:knj_threadpool] = nil
        end
      end
    end
  end
  
  #Returns true if the worker is currently working with a block.
  def busy?
    return true if @blockdata
  end
  
  #Returns the ID of the worker.
  def id
    return @args[:id]
  end
  
  #Kills the current thread and restarts the worker.
  def restart
    @mutex_tp.synchronize do
      @thread.kill
      
      if @blockdata
        @blockdata[:runned] = true
        @blockdata[:running] = false
        
        begin
          sleep 0.1
          raise "The worker was stopped during execution of the block."
        rescue Exception => e
          @blockdata[:error] = e
        end
      end
      
      #Dont run the job again - remove it from the queue.
      @tp.blocks.delete(@blockdata)
      @blockdata = nil
      @running = false
      
      #Spawn a new thread - we killed the previous.
      self.spawn_thread
    end
  end
  
  #Sleeps the thread.
  def stop
    @mutex_tp.synchronize do
      @thread.stop
    end
  end
  
  #Kills the thread.
  def kill
    @mutex_tp.synchronize do
      @thread.kill
    end
  end
end