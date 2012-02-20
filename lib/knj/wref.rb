require "weakref"

#A weak-reference that wont bite you in the ass like the one in Ruby 1.9.
class Knj::Wref
  def initialize(obj)
    @weakref = WeakRef.new(obj)
    @class = obj.class.name
    @id = @class.__id__
  end
  
  #Returns the object that this weak reference holds or throws WeakRef::RefError.
  def get
    obj = @weakref.__getobj__ if @weakref
    
    if !@weakref or @class != obj.class.name or @id != obj.__id__
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
    @class = nil
    @id = nil
    @weakref = nil
  end
  
  #Make Wref compatible with the normal WeakRef.
  alias weakref_alive? alive?
  alias __getobj__ get
end

class Knj::Wref_map
  def initialize(args = {})
    @args = args
    @map = {}
  end
  
  #Sets a new object in the map with a given ID.
  def set(id, obj)
    @map[id] = Knj::Wref.new(obj)
  end
  
  #Returns a object by ID or raises a RefError.
  def get(id)
    raise WeakRef::RefError if !@map.key?(id)
    
    begin
      return @map[id].get
    rescue WeakRef::RefError => e
      @map[id].destroy
      @map.delete(id)
      raise e
    end
  end
  
  #Make it hash-compatible.
  alias [] get
  alias []= set
  
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
    @map.each_index do |key|
      begin
        @map[key].get #this will remove the key if the object no longer exists.
      rescue WeakRef::RefError
        #ignore.
      end
    end
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
end