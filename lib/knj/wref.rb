require "weakref" if RUBY_ENGINE == "jruby"

#A weak-reference that wont bite you in the ass like the one in Ruby 1.9.
class Knj::Wref
  attr_reader :class_name, :id
  
  def initialize(obj)
    if RUBY_ENGINE == "jruby"
      @weakref = WeakRef.new(obj)
    else
      @class_name = obj.class.name.to_sym
      @id = obj.__id__
    end
  end
  
  #Returns the object that this weak reference holds or throws Knj::Wref::Recycled.
  def get
    if RUBY_ENGINE == "jruby"
      begin
        return @weakref.__getobj__ if @weakref
      rescue WeakRef::RefError
        raise Knj::Wref::Recycled
      end
    else
      begin
        obj = ObjectSpace._id2ref(@id)
        
        if @class_name != obj.class.name.to_sym or @id != obj.__id__
          self.destroy
          raise Knj::Wref::Recycled
        end
        
        return obj
      rescue RangeError
        raise Knj::Wref::Recycled
      end
    end
  end
  
  #Returns true if the reference is still alive.
  def alive?
    begin
      self.get
      return true
    rescue Knj::Wref::Recycled
      return false
    end
  end
  
  #Removes all data from this object.
  def destroy
    @weakref = nil
    @class_name = nil
    @id = nil
  end
  
  #Make Wref compatible with the normal WeakRef.
  alias weakref_alive? alive?
  alias __getobj__ get
end

class Knj::Wref_map
  def initialize(args = {})
    @map = {}
  end
  
  #Unsets everything to free up memory.
  def destroy
    @map.clear
    @map = nil
  end
  
  #Sets a new object in the map with a given ID.
  def set(id, obj)
    @map[id] = Knj::Wref.new(obj)
    return nil
  end
  
  #Returns a object by ID or raises a RefError.
  def get(id)
    raise Knj::Wref::Recycled if !@map.key?(id)
    
    begin
      return @map[id].get
    rescue Knj::Wref::Recycled => e
      begin
        @map[id].destroy
      rescue NoMethodError
        #happens if the object already got destroyed by another thread - ignore.
      end
      
      @map.delete(id)
      raise e
    end
  end
  
  #Make it hash-compatible.
  def key?(key)
    return @map.key?(key)
  end
  
  def length
    return @map.length
  end
  
  alias has_key? key?
  alias [] get
  alias []= set
  
  #The same as 'get' but returns nil instead of WeakRef-error. This can be used to avoid writing lots of code.
  def get!(id)
    begin
      return self.get(id)
    rescue Knj::Wref::Recycled
      return nil
    end
  end
  
  #Scans the whole map and removes dead references.
  def clean
    @map.keys.each do |key|
      begin
        self.get(key) #this will remove the key if the object no longer exists.
      rescue Knj::Wref::Recycled
        #ignore.
      end
    end
    
    return nil
  end
  
  #Returns true if a given key exists and the object it holds is alive.
  def valid?(key)
    return false if !@map.key?(key)
    
    begin
      @map[key].get
      return true
    rescue Knj::Wref::Recycled
      return false
    end
  end
end

class Knj::Wref::Recycled < RuntimeError
  
end