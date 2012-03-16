require "weakref"

#A weak-reference that wont bite you in the ass like the one in Ruby 1.9.
class Knj::Wref
  attr_reader :class_name, :id, :map, :map_id, :spawned
  
  #Yields debug-output for every weak-ref that is alive.
  def self.debug_wrefs
    ObjectSpace.each_object(Knj::Wref) do |wref|
      begin
        obj = wref.get
      rescue WeakRef::RefError
        yield("str" => "Dead wref: #{wref.class_name} (#{wref.id})", "alive" => false, "wref" => wref)
        next
      end
      
      yield("str" => "Alive wref: #{wref.class_name} (#{wref.id})", "alive" => true, "wref" => wref, "obj" => obj)
    end
  end
  
  def initialize(obj)
    @weakref = WeakRef.new(obj)
    @class_name = obj.class.name.to_sym
    @id = obj.__id__
  end
  
  #Returns the object that this weak reference holds or throws WeakRef::RefError.
  def get
    obj = @weakref.__getobj__ if @weakref
    
    #The class-check is because ID's can be reused in Ruby 1.9 which breaks the normal WeakRef-implementation.
    if !@weakref or @class_name != obj.class.name.to_sym or @id != obj.__id__
      self.destroy
      raise WeakRef::RefError
    end
    
    return obj
  end
  
  #Returns true if the reference is still alive.
  def alive?
    begin
      self.get
      return true
    rescue WeakRef::RefError
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
  def initialize(args = nil)
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
    raise WeakRef::RefError if !@map.key?(id)
    
    begin
      return @map[id].get
    rescue WeakRef::RefError => e
      begin
        @map[id].destroy
      rescue NoMethodError
        #happens if the object already got destroyed by another thread - ignore.
      end
      
      @map.delete(id)
      raise e
    end
  end
  
  #The same as 'get' but returns nil instead of WeakRef-error. This can be used to avoid writing lots of code.
  def get!(id)
    begin
      return self.get(id)
    rescue WeakRef::RefError
      return nil
    end
  end
  
  #Scans the whole map and removes dead references.
  def clean
    @map.keys.each do |key|
      begin
        self.get(key) #this will remove the key if the object no longer exists.
      rescue WeakRef::RefError
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
    rescue WeakRef::RefError
      return false
    end
  end
  
  #Returns true if the given key exists in the hash.
  def key?(key)
    return @map.key?(key)
  end
  
  #Returns the length of the hash. This may not be true since invalid objects is also counted.
  def length
    return @map.length
  end
  
  #Cleans the hash and returns the length. This is slower but more accurate than the ordinary length that just returns the hash-length.
  def length_valid
    self.clean
    return @map.length
  end
  
  #Deletes a key in the hash.
  def delete(key)
    @map.delete(key)
  end
  
  #Make it hash-compatible.
  alias has_key? key?
  alias [] get
  alias []= set
end