#This class behaves like a normal thread - but it shows error-messages and tracebacks. Normal threads dont do that.
class Knj::Thread < Thread
  attr_accessor :data
  
  def initialize(*args)
    @data = {}
    raise "No block was given." if !block_given?
    
    self.abort_on_exception = true
    super(*args) do
      begin
        yield(*args)
      rescue SystemExit
        exit
      rescue Exception => e
        print Knj::Errors.error_str(e)
      end
    end
  end
  
  def [](key)
    return @data[key]
  end
  
  def []=(key, value)
    return @data[key] = value
  end
end