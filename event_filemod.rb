class Knj::Event_filemod
	attr_reader :args
	
	def initialize(args, &block)
		@args = args
		@run = true
		
		@args[:wait] = 1 if !@args.has_key?(:wait)
		
		@mtimes = {}
		args[:paths].each do |path|
			@mtimes[path] = File.mtime(path)
		end
		
		Knj::Thread.new do
			while @run do
				if !@args
					break
				end
				
				@args[:paths].each do |path|
					changed = false
					
					if !@mtimes.has_key?(path)
						@mtimes[path] = File.mtime(path)
					end
					
					begin
						newdate = File.mtime(path)
					rescue Errno::ENOENT
						#file does not exist.
						changed = true
					end
					
					if !changed and newdate and newdate > @mtimes[path]
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
	
	def destroy
		@mtimes = {}
		@run = false
		@args = nil
	end
end