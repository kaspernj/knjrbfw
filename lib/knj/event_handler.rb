class Knj::Event_handler
	def initialize(args = {})
		@args = args
		@events = {}
	end
	
	def add_event(event)
		raise "No name given." if !event[:name]
		
		@events[event[:name]] = [] if !@events.has_key?(event[:name])
		@events[event[:name]] = {
			:event => event,
			:callbacks => {},
			:callbacks_count => 0
		}
	end
	
	def add_events(*events)
		events.each do |event|
			self.add_event(:name => event)
		end
	end
	
	def connect(name, &block)
		raise "No such event: '#{name}'." if !@events.has_key?(name)
		
		event = @events[name]
		
		if event[:event].has_key?(:connections_max) and event[:callbacks].length >= event[:event][:connections_max].to_i
			raise "The event '#{name}' has reached its maximum connections of '#{event[:event][:connections_max]}'"
		end
		
		event[:callbacks_count] += 1
		count = event[:callbacks_count]
		event[:callbacks][count] = {
			:block => block
		}
		
		return count
	end
	
	def disconnect(name, callback_id)
		raise "No such event: '#{name}'." if !@events.has_key?(name)
		raise "No such connection: '#{name}' --> '#{callback_id}'" if !@events[name].has_key?(callback_id)
		@events[name][callback_id].clear
		@events[name].delete(callback_id)
	end
	
	def count_connects(name)
		raise "No such event." if !@events.has_key?(name)
		return @events[name][:callbacks].length
	end
	
	def connected?(name)
		raise "No such event." if !@events.has_key?(name)
		return !@events[name][:callbacks].empty?
	end
	
	def call(name, *args)
		raise "No such event: '#{name}'." if !@events.has_key?(name)
		event = @events[name]
		ret = nil
		event[:callbacks].clone.each do |callback_id, callback_hash|
			ret = callback_hash[:block].call(name, *args)
		end
		
		return ret
	end
end