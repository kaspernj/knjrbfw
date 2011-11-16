require "knj/event_handler"

class Knj::Datarow_custom
  def self.events
    if !@events
      @events = Knj::Event_handler.new
      @events.add_event(:name => :add, :connections_max => 1)
      @events.add_event(:name => :update, :connections_max => 1)
      @events.add_event(:name => :data_from_id, :connections_max => 1)
    end
    
    return @events
  end
  
  def self.add(d)
    return @events.call(:add, d)
  end
  
  def initialize(d)
    data = d.data
    
    if data.is_a?(Hash)
      @data = Knj::ArrayExt.hash_sym(data)
    else
      data = self.class.events.call(:data_from_id, Knj::Hash_methods.new(:id => data))
      raise "No data was received from the event: 'data_from_id'." if !data
      @data = Knj::ArrayExt.hash_sym(data)
    end
  end
  
  def update(data)
    return self.class.events.call(:update, Knj::Hash_methods.new(:object => self, :data => data))
  end
  
  def [](key)
    raise "No such key: '#{key}'." if !@data.key?(key)
    return @data[key]
  end
  
  def id
    return self[:id]
  end
  
  def name
    if @data.key?(:title)
      return @data[:title]
    elsif @data.key?(:name)
      return @data[:name]
    end
    
    obj_methods = self.class.instance_methods(false)
    [:name, :title].each do |method_name|
      return self.method(method_name).call if obj_methods.index(method_name)
    end
    
    raise "Couldnt figure out the title/name of the object on class #{self.class.name}."
  end
end