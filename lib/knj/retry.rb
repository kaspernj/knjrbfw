class Knj::Retry
	def self.try(args = {}, &block)
		raise "No block was given." if !block_given?
		
		args[:tries] = 3 if !args[:tries]
		tries = []
		error = nil
		
		args[:tries].to_i.downto(1) do |count|
			error = nil
			dobreak = false
			
			begin
				if args[:timeout]
					begin
						Timeout.timeout(args[:timeout]) do
							block.call
							dobreak = true
							break
						end
					rescue Timeout::Error => e
						doraise = e if count <= 1
						error = e
						sleep(args[:wait]) if args[:wait] and !doraise
					end
				else
					block.call
					dobreak = true
					break
				end
			rescue Exception => e
				if e.class == Interrupt
					raise e if !args.key?(:interrupt) or args[:interrupt]
				elsif e.class == SystemExit
					raise e if !args.key?(:exit) or args[:exit]
				elsif count <= 1 or (args.key?(:errors) and args[:errors].index(e.class) == nil)
					doraise = e
				elsif args.key?(:errors) and args[:errors].index(e.class) != nil
					#given error was in the :errors-array - do nothing. Maybe later it should be logged and returned in a stats-hash or something? - knj
				end
				
				error = e
				sleep(args[:wait]) if args[:wait] and !doraise
			end
			
			if doraise
				if args[:return_error]
					tries << {:error => error}
					return {
						:tries => tries,
						:result => false
					}
				else
					raise e
				end
			elsif error
				tries << {:error => error}
			end
			
			break if dobreak
		end
		
		res = true
		res = false if error
		
		return {
			:tries => tries,
			:result => res
		}
	end
end