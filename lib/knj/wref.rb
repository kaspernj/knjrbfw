#A simple weak-reference framework with mapping. Only handles the referencing of objects.
class Knj::Wref
  attr_reader :class_name, :id
  
  def initialize(obj)
    @id = obj.__id__
    
    if RUBY_ENGINE == "jruby"
      @weakref = java.lang.ref.WeakReference.new(obj)
    else
      @class_name = obj.class.name.to_sym
      
      if obj.respond_to?("__object_unique_id__")
        @unique_id = obj.__object_unique_id__
      end
    end
  end
  
  #Returns the object that this weak reference holds or throws Knj::Wref::Recycled.
  def get
    begin
      raise Knj::Wref::Recycled if !@class_name or !@id
      
      if RUBY_ENGINE == "jruby"
        obj = @weakref.get
        
        if obj == nil
          STDOUT.print "Java weak recycled!\n"
          raise Knj::Wref::Recycled
        else
          STDOUT.print "Java weak works!\n"
          return obj
        end
      else
        obj = ObjectSpace._id2ref(@id)
      end
      
      #Some times this name will be nil for some reason - knj
      obj_class_name = obj.class.name
      
      if !obj_class_name or @class_name != obj_class_name.to_sym or @id != obj.__id__
        raise Knj::Wref::Recycled
      end
      
      if @unique_id
        if !obj.respond_to?("__object_unique_id__") or obj.__object_unique_id__ != @unique_id
          raise Knj::Wref::Recycled
        end
      end
      
      return obj
    rescue RangeError, TypeError
      raise Knj::Wref::Recycled
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
  
  #Make Wref compatible with the normal WeakRef.
  alias weakref_alive? alive?
  alias __getobj__ get
end

class Knj::Wref_map
  def initialize(args = nil)
    @map = {}
    @ids = {}
    @mutex = Mutex.new
  end
  
  #Sets a new object in the map with a given ID.
  def set(id, obj)
    wref = Knj::Wref.new(obj)
    
    @mutex.synchronize do
      @map[id] = wref
      @ids[obj.__id__] = id
    end
    
    #JRuby cant handle this atm... Dunno why...
    if RUBY_ENGINE != "jruby"
      ObjectSpace.define_finalizer(obj, self.method("delete_by_id"))
    end
    
    return nil
  end
  
  #Returns a object by ID or raises a RefError.
  def get(id)
    begin
      @mutex.synchronize do
        raise Knj::Wref::Recycled if !@map.key?(id)
        return @map[id].get
      end
    rescue Knj::Wref::Recycled => e
      self.delete(id)
      raise e
    end
  end
  
  #The same as 'get' but returns nil instead of WeakRef-error. This can be used to avoid writing lots of code.
  def get!(id)
    begin
      return self.get(id)
    rescue Knj::Wref::Recycled
      return nil
    end
  end
  
  #Scans the whole map and removes dead references. After the implementation of automatic clean-up by using ObjectSpace.define_finalizer, there should be no reason to call this method.
  def clean
    keys = nil
    @mutex.synchronize do
      keys = @map.keys
    end
    
    keys.each do |key|
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
    @mutex.synchronize do
      return false if !@map.key?(key)
      
      begin
        @map[key].get
        return true
      rescue Knj::Wref::Recycled
        return false
      end
    end
  end
  
  #Returns true if the given key exists in the hash.
  def key?(key)
    @mutex.synchronize do
      return @map.key?(key)
    end
  end
  
  #Returns the length of the hash. This may not be true since invalid objects is also counted.
  def length
    @mutex.synchronize do
      return @map.length
    end
  end
  
  #Cleans the hash and returns the length. This is slower but more accurate than the ordinary length that just returns the hash-length.
  def length_valid
    self.clean
    
    @mutex.synchronize do
      return @map.length
    end
  end
  
  #Deletes a key in the hash.
  def delete(key)
    @mutex.synchronize do
      wref = @map[key]
      @ids.delete(wref.id) if wref
      @map.delete(key)
    end
  end
  
  #This method is supposed to remove objects when finalizer is called by ObjectSpace.
  def delete_by_id(object_id)
    @mutex.synchronize do
      id = @ids[object_id]
      @map.delete(id)
      @ids.delete(object_id)
    end
  end
  
  #Make it hash-compatible.
  alias has_key? key?
  alias [] get
  alias []= set
end

class Knj::Wref::Recycled < RuntimeError; end