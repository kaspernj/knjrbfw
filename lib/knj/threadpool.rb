#A small threadpool framework.
class Knj::Threadpool
  def self.worker_data
    raise "This thread is not running via the threadpool." if !Thread.current[:knj_threadpool]
    return Thread.current[:knj_threadpool]
  end
  
  attr_reader :workers, :blocks, :mutex, :args, :events
  
  #Constructor.
  #===Examples
  # tp = Knj::Threadpool.new(:threads => 5)
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
  
  #Starts the threadpool. This is automatically called from the constructor.
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
  
  #Stops the threadpool.
  def stop
    if @running
      @workers.each do |worker|
        if !worker.running
          STDOUT.print "Killing worker...\n"
          worker.kill
          @workers.delete(worker)
          STDOUT.print "Done killing.\n"
        end
      end
      
      @running = false
    end
  end
  
  #Runs the given block, waits for the result and returns the result.
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
  
  #Runs the given block in the threadpool asynced. Returns a 'Knj::Threadpool::Asynced'-object that can be used to get the result and more.
  def run_async(*args, &block)
    raise "No block given." if !block_given?
    
    @mutex.synchronize do
      blockdata = {:block => block, :running => false, :runned => false, :args => args}
      @blocks << blockdata
      return Knj::Threadpool::Asynced.new(blockdata)
    end
  end
  
  #Returns a new block to be runned if there is one. Otherwise false.
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

#This is the threadpool worker-object. No need to spawn this manually.
class Knj::Threadpool::Worker
  attr_reader :running
  
  #Constructor. Should not be called manually.
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
        break if !@sleep or !@tp
        
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
          @running = true
          res = @blockdata[:block].call(*@blockdata[:args])
        rescue => e
          @mutex_tp.synchronize do
            @blockdata[:error] = e
          end
        ensure
          #Reset thread.
          Thread.current[:knj_threadpool] = nil
          
          #Set running-status on worker.
          @running = false
          
          #Update block-data.
          @mutex_tp.synchronize do
            @blockdata[:result] = res if res
            @blockdata[:runned] = true
            @blockdata[:running] = false
          end
          
          #Try to avoid slowdown of sleep by checking if there is a new block right away.
          @blockdata = @tp.get_block
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
        rescue => e
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
  
  #Kills the thread.
  def kill
    @mutex_tp.synchronize do
      @thread.kill
    end
  end
end

#An object of this class will be returned when calling 'run_async'.
class Knj::Threadpool::Asynced
  #Constructor. Should not be called manually.
  def initialize(args)
    @args = args
  end
  
  #Returns true if the asynced job is still running.
  def running?
    return true if @args[:running]
    return false
  end
  
  #Returns true if the asynced job is done running.
  def done?
    return true if @args[:runned] or @args.empty? or @args[:error]
    return false
  end
  
  #Returns true if the asynced job is still waiting to run.
  def waiting?
    return true if !@args.empty? and !@args[:running] and !@args[:runned]
    return false
  end
  
  #Raises error if one has happened in the asynced job.
  def error!
    raise @args[:error] if @args.key?(:error)
  end
  
  #Sleeps until the asynced job is done. If an error occurred in the job, that error will be raised when calling the method.
  def join
    loop do
      self.error!
      break if self.done?
      sleep 0.1
    end
    
    self.error!
  end
  
  #Returns the result of the job. If an error occurred in the job, that error will be raised when calling the method.
  def result(args = nil)
    self.join if args and args[:wait]
    raise "Not done yet." unless self.done?
    self.error!
    return @args[:result]
  end
end