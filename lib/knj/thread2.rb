class Knj::Thread2
  def initialize(args = {}, &block)
    @args = args
    @block = block if block_given?
    @callbacks = {}
  end
  
  def connect(signal, &block)
    @callbacks[signal] = [] if !@callbacks.key?(signal)
    @callbacks[signal] << block
  end
  
  def call(signal, *args)
    return false if !@callbacks.key?(signal)
    @callbacks[signal].each do |block|
      block.call(*args)
    end
    
    return {:count => count}
  end
  
  def run
    Thread.new do
      abort_on_exception = true
      call(:on_run)
      
      begin
        @block.call
      rescue SystemExit
        call(:on_exit)
        exit
      rescue Exception => e
        call(:on_error, e)
        
        if !@args.key?(:print_error) or @args[:print_error]
          print "Error: "
          puts e.inspect
          print "\n"
          puts e.backtrace
          print "\n\n"
        end
      end
      
      call(:on_done)
    end
  end
end