#This class behaves like a normal thread - but it shows error-messages and tracebacks. Normal threads dont do that.
class Knj::Thread < Thread
	attr_accessor :data
	
	def initialize(*args, &block)
		@data = {}
		@args = args if !block
		@callbacks = {}
		raise "No block was given." if !block_given?
		
		abort_on_exception = true
		super(*args) do
			begin
				call(:on_run)
				block.call(*@args)
				call(:on_done)
			rescue SystemExit
				exit
			rescue Exception => e
				print "Error: "
				puts e.inspect
				print "\n"
				puts e.backtrace
				print "\n\n"
			end
		end
	end
	
	def connect(signal, &block)
		@callbacks[signal] = [] if !@callbacks.has_key?(signal)
		@callbacks[signal] << block
	end
	
	def call(signal, *args)
		return false if !@callbacks.has_key?(signal)
		@callbacks[signal].each do |block|
			block.call(*args)
		end
	end
	
	def [](key)
		return @data[key]
	end
	
	def []=(key, value)
		return @data[key] = value
	end
end