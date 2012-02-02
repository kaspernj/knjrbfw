class Knj::Hash_methods < Hash
  def initialize(hash = {})
    self.update(hash)
  end
  
  def db
    return self[:db]
  end
  
  def ob
    return self[:ob]
  end
  
  def args
    return self[:args]
  end
  
  def data
    return self[:data]
  end
  
  def method_missing(method, *args)
    method = method.to_sym
    return self[method] if self.key?(method)
    
    raise "No such method '#{method}' on class '#{self.class.name}'"
  end
end