#This class is used for event handeling.
#===Examples
# events = Knj::Event_handler.new
# events.add_event(:name => :test_event)
# events.connect(:test_event) do |*args|
#   print "Test-event called!\n"
# end
# 
# events.call(:test_event) #=> prints "Test-event called!\n"
class Knj::Event_handler
  #Sets various used variables.
  def initialize(args = {})
    @args = args
    @events = {}
  end
  
  #Adds information about a new event.
  #===Examples
  # events.add_event(:name => :test_event)
  def add_event(event)
    raise "No name given." if !event[:name]
    
    @events[event[:name]] = [] if !@events.key?(event[:name])
    @events[event[:name]] = {
      :event => event,
      :callbacks => {},
      :callbacks_count => 0
    }
  end
  
  #Adds multiple events.
  #===Examples
  # events.add_events(:test_event, :another_event, :a_third_event)
  def add_events(*events)
    events.each do |event|
      self.add_event(:name => event)
    end
  end
  
  #Connects the given block to a given event.
  #===Examples
  # events.connect(:test_event){ |*args| print "Test event!\n"}
  def connect(name, &block)
    raise "No such event: '#{name}'." if !@events.key?(name)
    
    event = @events[name]
    
    if event[:event].key?(:connections_max) and event[:callbacks].length >= event[:event][:connections_max].to_i
      raise "The event '#{name}' has reached its maximum connections of '#{event[:event][:connections_max]}'"
    end
    
    event[:callbacks_count] += 1
    count = event[:callbacks_count]
    event[:callbacks][count] = {
      :block => block
    }
    
    return count
  end
  
  #Returns true if the given event is connected.
  #===Examples
  # print "Test-event is connected!" if events.connected?(:test_event)
  def connected?(name)
    raise "No such event." if !@events.key?(name)
    return !@events[name][:callbacks].empty?
  end
  
  #Disconnects an event.
  #===Examples
  # connection_id = events.connect(:test_event){print "test event!}
  # events.disconnect(:test_event, connection_id)
  # events.call(:test_event) #=> Doesnt print 'test event!'.
  def disconnect(name, callback_id)
    raise "No such event: '#{name}'." if !@events.key?(name)
    raise "No such connection: '#{name}' --> '#{callback_id}'" if !@events[name].key?(callback_id)
    @events[name][callback_id].clear
    @events[name].delete(callback_id)
  end
  
  #Returns how many blocks have been connected to an event.
  #===Examples
  # print "More than five connections to test-event!" if events.count_events(:test_event) > 5
  def count_connects(name)
    raise "No such event." if !@events.key?(name)
    return @events[name][:callbacks].length
  end
  
  #Calls an added event.
  #===Examples
  # events.call(:test_event, {:data => 1})
  def call(name, *args)
    raise "No such event: '#{name}'." if !@events.key?(name)
    event = @events[name]
    ret = nil
    event[:callbacks].clone.each do |callback_id, callback_hash|
      ret = callback_hash[:block].call(name, *args)
    end
    
    return ret
  end
end