#A normal hash that uses 'method_missing' to be able to call keys by using methods. It is heavily used by Knj::Objects and have some pre-defined methods because of it to optimize performance.
#===Examples
# hm = Knj::Hash_methods(:test => "Test")
# print hm.test
class Knj::Hash_methods < Hash
  #Spawns the object and takes a hash as argument.
  def initialize(hash = {})
    self.update(hash)
  end
  
  #Returns the db-key.
  def db
    return self[:db]
  end
  
  #Returns the ob-key.
  def ob
    return self[:ob]
  end
  
  #Returns the args-key.
  def args
    return self[:args]
  end
  
  #Returns the data-key.
  def data
    return self[:data]
  end
  
  #Proxies methods into the hash as keys.
  def method_missing(method, *args)
    method = method.to_sym
    return self[method] if self.key?(method)
    
    raise "No such method '#{method}' on class '#{self.class.name}'"
  end
end