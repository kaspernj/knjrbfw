class Knj::Threadpool
	attr_reader :workers, :blocks, :mutex, :args, :events
	
	def initialize(args = {})
		@args = args
		@args[:sleep] = 0.01 if !@args.key?(:sleep)
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
		
		@thread = Knj::Thread.new do
			loop do
				if !@blockdata
					sleep @sleep
					@blockdata = @tp.get_block if !@blockdata
				end
				
				next if !@blockdata
				
				res = nil
				raise "No block in blockdata?" if !@blockdata[:block]
				
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
							puts e.inspect
							puts e.backtrace
						end
					ensure
						@mutex_tp.synchronize do
							@blockdata.clear
							@tp.blocks.delete(@blockdata)
						end
						
						#Try to avoid slowdown of sleep by checking if there is a new block right away.
						@blockdata = @tp.get_block
					end
				end
			end
		end
	end
	
	def busy?
		return true if @blockdata
	end
	
	def id
		return @args[:id]
	end
	
	def kill
    return false if !@mutex_tp
    
    @mutex_tp.synchronize do
      @thread.kill
      @args = nil
      @tp = nil
      @mutex_tp = nil
      @sleep = nil
      @blockdata = nil
      @thread = nil
    end
	end
end