class Knj::Threadhandler
	def initialize(args = {})
		@args = args
		@count = 0
		@objects = {}
	end
	
	def on_spawn_new(&block)
		@spawn_new_block = block
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
		objdata[:free] = true
	end
end