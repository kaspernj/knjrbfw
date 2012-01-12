class Knj::Process
  #Constructor. Sets in, out and various other needed variables.
  def initialize(args = {})
    @args = args
    @in = @args[:in]
    @out = @args[:out]
    @on_send = @args[:on_send]
    @in_count = 0
    @out_count = 0
    @out_answers = {}
    @out_mutex = Mutex.new
  end
  
  #Listens for a new incoming object.
  def listen
    loop do
      str = @in.gets
      data = str.strip.split(":")
      
      res = @in.read(data[2])
      obj = Marshal.load(res)
      
      if data[0] == "answer"
        @out_answers[res[1]] = obj
      elsif data[0] == "send"
        @on_send.call(:process => self, :no => res[1], :obj => obj)
      else
        raise "Unknown command: '#{res[0]}'."
      end
    end
  end
  
  #Answers a send.
  def answer(id, obj)
    str = Marshal.dump(obj)
    @out.write("answer:#{id}:#{str.length}\n#{str}")
  end
  
  #Sends a command to the client.
  def send(obj, wait_for_answer = true)
    @out_mutex.synchronize do
      my_id = @out_count
      @out_count += 1
    end
    
    str = Marshal.dump(obj)
    @out.write("send:#{my_id}:#{str.length}\n#{str}")
    
    ret = {:id => my_id}
    
    if wait_for_answer
      ret[:result] = self.read_answer(my_id)
    end
    
    return ret
  end
  
  #Returns true if an answer with a certain ID has arrived.
  def has_answer?(id)
    return @out_answers.key?(id)
  end
  
  #Waits for data with a certain ID and returns it when it exists.
  def read_answer(count)
    loop do
      if @out_answers[count]
        ret = @out_answers[count]
        @out_answers.delete(count)
        return ret
      end
      
      sleep 0.1
    end
  end
end