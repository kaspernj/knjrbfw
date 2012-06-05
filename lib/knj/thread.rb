#This class behaves like a normal thread - but it shows error-messages and tracebacks. Normal threads dont do that.
class Knj::Thread < Thread
  attr_accessor :data
  
  #Initializes the thread and passes any given arguments to the thread-block.
  def initialize(*args)
    raise "No block was given." unless block_given?
    
    super(*args) do
      begin
        yield(*args)
      rescue SystemExit
        exit
      rescue => e
        print "#{Knj::Errors.error_str(e)}\n\n"
      end
    end
    
    @data = {}
  end
  
  #Returns a key from the data-hash.
  def [](key)
    return @data[key]
  end
  
  #Sets a key on the data-hash.
  def []=(key, value)
    return @data[key] = value
  end
end