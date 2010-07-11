#This class behaves like a normal thread - but it shows error-messages and tracebacks. Normal threads dont do that.
class Knj::Thread < Thread
	def initialize(*paras, &block)
		if !block_given?
			raise "No block was given."
		end
		
		Thread.abort_on_exception = true
		super(*paras) do
			begin
				block.call(*paras)
			rescue Exception => e
				print "Error: "
				puts e.inspect
				print "\n"
				puts e.backtrace
				print "\n\n"
			end
		end
	end
end