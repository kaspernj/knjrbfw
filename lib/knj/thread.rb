#This class behaves like a normal thread - but it shows error-messages and tracebacks. Normal threads dont do that.
class Knj::Thread < Thread
	attr_accessor :data
	
	def initialize(*args, &block)
		@data = {}
		raise "No block was given." if !block_given?
		
		abort_on_exception = true
		super(*args) do
			begin
				block.call(*args)
			rescue SystemExit
				exit
			rescue Exception => e
        print Knj::Errors.error_str(e)
			end
		end
	end
	
	def [](key)
		return @data[key]
	end
	
	def []=(key, value)
		return @data[key] = value
	end
end