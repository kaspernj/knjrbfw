class Knj::Process
  #Constructor. Sets in, out and various other needed variables.
  def initialize(args = {})
    @args = args
    @in = @args[:in]
    @out = @args[:out]
    @on_rec = @args[:on_rec]
    @in_count = 0
    @out_count = 0
    @out_answers = {}
    @out_mutex = Mutex.new
    @debug = @args[:debug]
    @args[:sleep_answer] = 0.001 if !@args.key?(:sleep_answer)
    
    if @args[:listen]
      require "#{$knjpath}/thread"
      @listen_thread = Thread.new do
        begin
          self.listen
        rescue Exception => e
          STDOUT.print Knj::Errors.error_str(e)
        end
      end
    end
  end
  
  def kill_listen
    @listen_thread.kill
  end
  
  #Listens for a new incoming object.
  def listen
    loop do
      str = @in.gets
      data = str.strip.split(":")
      raise "Expected length of 3 but got: '#{data.length}'." if data.length != 3
      
      raise "Invalid ID: '#{data[1]}'." if data[1].to_s.strip.length <= 0
      id = data[1].to_i
      
      raise "Invalid length: '#{data[2]}'." if data[2].to_s.strip.length <= 0
      length = data[2].to_i
      
      print "Received ID #{id}.\n" if @debug
      print "Reading #{length} bytes.\n" if @debug
      res = @in.read(length)
      print "Got content for '#{id}'.\n" if @debug
      
      obj = Marshal.load(res)
      
      if data[0] == "answer"
        @out_answers[id] = obj
      elsif data[0] == "send"
        @on_rec.call(Knj::Process::Resultobject.new(:process => self, :id => id, :obj => obj))
      else
        raise "Unknown command: '#{res[0]}'."
      end
    end
  end
  
  #Answers a send.
  def answer(id, obj)
    print "Answering #{id} (#{obj}).\n" if @debug
    str = Marshal.dump(obj)
    
    @out_mutex.synchronize do
      @out.write("answer:#{id}:#{str.length}\n#{str}")
      #@out.write(str)
    end
  end
  
  #Sends a command to the client.
  def send(obj, wait_for_answer = true)
    my_id = nil
    @out_mutex.synchronize do
      my_id = @out_count
      @out_count += 1
      print "Sending #{my_id} (#{obj}).\n" if @debug
      str = Marshal.dump(obj)
      @out.write("send:#{my_id}:#{str.length}\n#{str}")
      #@out.write(str)
    end
    
    if wait_for_answer
      return self.read_answer(my_id)
    end
    
    return {:id => my_id}
  end
  
  #Returns true if an answer with a certain ID has arrived.
  def has_answer?(id)
    return @out_answers.key?(id)
  end
  
  #Waits for data with a certain ID and returns it when it exists.
  def read_answer(id)
    print "Reading answer (#{id}).\n" if @debug
    sleep @args[:sleep_answer] until @out_answers.key?(id)
    print "Returning answer (#{id}).\n" if @debug
    ret = @out_answers[id]
    @out_answers.delete(id)
    return ret
  end
end

class Knj::Process::Resultobject
  def initialize(args)
    @args = args
  end
  
  def obj
    return @args[:obj]
  end
  
  def process
    return @args[:process]
  end
  
  def id
    return @args[:id]
  end
  
  def answer(obj)
    @args[:process].answer(@args[:id], obj)
  end
end