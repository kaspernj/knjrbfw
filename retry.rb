class Knj::Retry
	def self.try(args = {}, &block)
		raise "No block was given." if !block_given?
		
		args[:tries] = 3 if !args[:tries]
		
		args[:tries].to_i.downto(1) do |count|
			begin
				if args[:timeout]
					begin
						Timeout.timeout(args[:timeout]) do
							block.call
							break
						end
					rescue Timeout::Error => e
						if count <= 1
							doraise = e
						end
					end
				else
					block.call
					break
				end
			rescue Exception => e
				if e.class == Interrupt
					raise e
				elsif e.class == SystemExit and (!args.has_key?(:exit) or args[:exit])
					exit
				elsif count <= 1 or (args.has_key?(:errors) and args[:errors].index(e.class) == nil)
					doraise = e
				elsif args.has_key?(:errors) and args[:errors].index(e.class) != nil
					#given error was in the :errors-array - do nothing. Maybe later it should be logged and returned in a stats-hash or something? - knj
				end
			end
			
			if doraise
				if !args.has_key?(:clean_backtrace) or args[:clean_backtrace]
					#Clean backtrace so its easier to debug.
					newtrace = []
					bt = e.backtrace
					
					bt.each do |trace|
						if trace.index("/retry.rb") == nil
							newtrace << trace
						end
					end
					
					e.set_backtrace(newtrace)
				end
				
				raise e
			end
		end
	end
end