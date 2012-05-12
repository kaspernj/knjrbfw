class Knj::Threadhandler
  attr_reader :inactive_blocks, :args, :activate_blocks, :mutex, :objects
  
  def initialize(args = {})
    require "#{$knjpath}errors"
    require "tsafe"
    
    @args = args
    @objects = []
    @args[:timeout] = 5 if !@args[:timeout]
    @args[:max] = 50 if !@args[:max]
    @inactive_blocks = []
    @activate_blocks = []
    @mutex = Mutex.new
    
    @thread_timeout = Thread.new do
      begin
        loop do
          sleep @args[:timeout]
          break if !@mutex
          check_inactive
        end
      rescue => e
        STDOUT.print Knj::Errors.error_str(e)
      end
    end
  end
  
  def on_spawn_new(&block)
    raise "Destroyed Knj::Threadhandler." if !@mutex
    @spawn_new_block = block
  end
  
  def on_inactive(&block)
    raise "Destroyed Knj::Threadhandler." if !@mutex
    @inactive_blocks << block
  end
  
  def on_activate(&block)
    raise "Destroyed Knj::Threadhandler." if !@mutex
    @activate_blocks << block
  end
  
  def destroy
    return false if !@mutex
    
    @thread_timeout.kill if @thread_timeout and @thread_timeout.alive?
    @thread_timeout = nil
    
    @mutex.synchronize do
      @objects.each do |data|
        @inactive_blocks.each do |block|
          data[:inactive] = true
          block.call(:obj => data[:object])
        end
      end
    end
    
    @args = nil
    @objects = nil
    @inactive_blocks = nil
    @activate_blocks = nil
    @mutex = nil
  end
  
  def check_inactive
    raise "Destroyed Knj::Threadhandler." if !@mutex
    @mutex.synchronize do
      cur_time = Time.now.to_i - @args[:timeout]
      @objects.each do |data|
        if data[:free] and !data[:inactive] and data[:free] < cur_time
          @inactive_blocks.each do |block|
            data[:inactive] = true
            block.call(:obj => data[:object])
          end
        end
      end
    end
  end
  
  def get_and_lock
    raise "Destroyed Knj::Threadhandler." if !@mutex
    newobj = nil
    sleep_do = false
    
    begin
      @mutex.synchronize do
        retdata = false
        @objects.each do |data|
          if data[:free]
            retdata = data
            break
          end
        end
        
        if retdata
          #Test if object is still free - if not, try again - knj.
          return get_and_lock if !retdata[:free]
          retdata[:free] = false
          
          if retdata[:inactive]
            @activate_blocks.each do |block|
              block.call(:obj => retdata[:object])
            end
            
            retdata.delete(:inactive)
          end
          
          return retdata[:object]
        end
        
        if @objects.length >= @args[:max]
          #The maximum amount of objects has already been spawned... Sleep 0.1 sec and try to lock an object again...
          raise Knj::Errors::Retry
        else
          #No free objects, but we can spawn a new one and use that...
          newobj = @spawn_new_block.call
          @objects << Tsafe::MonHash.new.merge(
            :free => false,
            :object => newobj
          )
          STDOUT.print "Spawned db and locked new.\n" if @args[:debug]
        end
      end
      
      return newobj
    rescue Knj::Errors::Retry
      STDOUT.print "All objects was taken - sleeping 0.1 sec and tries again.\n" #if @args[:debug]
      sleep 0.1
      retry
    end
  end
  
  def free(obj)
    @mutex.synchronize do
      return false if !@mutex or !@objects #something is trying to free and object, but the handler is destroyed. Dont crash but return false.
      
      freedata = false
      @objects.each do |data|
        if data[:object] == obj
          freedata = data
          break
        end
      end
      
      raise "Could not find that object in list." if !freedata
      STDOUT.print "Freed one.\n" if @args[:debug]
      freedata[:free] = Time.now.to_i
    end
  end
  
  #Executes the given block with an element and then frees it.
  def use
    raise "No block was given." if !block_given?
    
    obj = self.get_and_lock
    
    begin
      yield(obj)
    ensure
      self.free(obj)
    end
  end
end