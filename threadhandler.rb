class Knj::Threadhandler
	attr_reader :inactive_blocks, :args, :activate_blocks
	
	def initialize(args = {})
		@args = args
		@count = 0
		@objects = {}
		@args[:timeout] = 5 if !@args[:timeout]
		@inactive_blocks = []
		@activate_blocks = []
		
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
		cur_time = Time.new.to_i - @args[:timeout]
		@objects.clone.each do |key, data|
			if data[:free] and !data[:inactive] and data[:free] < cur_time
				@inactive_blocks.each do |block|
					data[:inactive] = true
					block.call(:obj => data[:object])
				end
			end
		end
	end
	
	def get_and_lock
		retkey = false
		@objects.clone.each do |key, data|
			if data[:free]
				retkey = key
				break
			end
		end
		
		if retkey
			objdata = @objects[retkey]
			
			#Test if object is still free - if not, try again - knj.
			return self.get_and_lock if !objdata[:free]
			
			objdata[:free] = false
			STDOUT.print "Got and locked #{retkey}\n" if @args[:debug]
			
			if objdata[:inactive]
				@activate_blocks.each do |block|
					block.call(:obj => objdata[:object])
				end
				
				objdata.delete(:inactive)
			end
			
			return objdata[:object]
		end
		
		newobj = @spawn_new_block.call
		@objects[@count] = {
			:free => false,
			:object => newobj
		}
		STDOUT.print "Spawned db and locked: #{@count}\n" if @args[:debug]
		@count += 1
		return newobj
	end
	
	def free(obj)
		freekey = false
		@objects.clone.each do |key, data|
			if data[:object] == obj
				freekey = key
				break
			end
		end
		
		if !freekey
			raise "Could not find that object in list."
		end
		
		STDOUT.print "Freed #{freekey}\n" if @args[:debug]
		objdata = @objects[freekey]
		objdata[:free] = Time.new.to_i
	end
end