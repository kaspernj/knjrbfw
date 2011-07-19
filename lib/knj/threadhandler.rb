class Knj::Threadhandler
	attr_reader :inactive_blocks, :args, :activate_blocks, :mutex
	
	def initialize(args = {})
		@args = args
		@objects = []
		@args[:timeout] = 5 if !@args[:timeout]
		@inactive_blocks = []
		@activate_blocks = []
		@mutex = Mutex.new
		
		@thread_timeout = Knj::Thread.new do
			loop do
				sleep @args[:timeout]
				check_inactive
			end
		end
	end
	
	def on_spawn_new(&block)
		@spawn_new_block = block
	end
	
	def on_inactive(&block)
		@inactive_blocks << block
	end
	
	def on_activate(&block)
		@activate_blocks << block
	end
	
	def check_inactive
		@mutex.synchronize do
			cur_time = Time.new.to_i - @args[:timeout]
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
		newobj = nil
		
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
			
			newobj = @spawn_new_block.call
			@objects << {
				:free => false,
				:object => newobj
			}
			STDOUT.print "Spawned db and locked new.\n" if @args[:debug]
		end
		
		return newobj
	end
	
	def free(obj)
		@mutex.synchronize do
			freedata = false
			@objects.each do |data|
				if data[:object] == obj
					freedata = data
					break
				end
			end
			
			raise "Could not find that object in list." if !freedata
			STDOUT.print "Freed one.\n" if @args[:debug]
			freedata[:free] = Time.new.to_i
		end
	end
end