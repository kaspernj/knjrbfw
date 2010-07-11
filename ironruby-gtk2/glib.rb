GLib = Module.new do
	class Timeout
		def self.add(time, &block)
			Thread.new(time, block) do |time, block|
				begin
					sleep(time / 1000)
					block.call
				rescue Exception => e
					puts e.inspect
					puts e.backtrace
				end
			end
		end
	end
end