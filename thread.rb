#This class behaves like a normal thread - but it shows error-messages and tracebacks. Normal threads dont do that.
class Knj::Thread < Thread
	attr_accessor :data
	
	def initialize(*paras, &block)
		@data = {}
		raise "No block was given." if !block_given?
		
		Thread.abort_on_exception = true
		super(*paras) do
			begin
				block.call(*paras)
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
	
	def [](key)
		return @data[key]
	end
	
	def []=(key, value)
		return @data[key] = value
	end
end