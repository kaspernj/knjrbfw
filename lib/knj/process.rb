require "#{$knjpath}/errors"
require "#{$knjpath}/thread"

class Knj::Process
  attr_reader :blocks
  
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
    @thread_error = nil
    @blocks = {}
    
    #Else the sockets might hang when waiting for results and stuff like that... - knj.
    @in.sync = true
    @out.sync = true
    
    if @args[:err]
      @err_thread = Knj::Thread.new do
        @args[:err].each_line do |str|
          if @args[:on_err]
            @args[:on_err].call(str)
          else
            $stderr.print "Process error: #{str}"
          end
        end
      end
    end
    
    if @args[:listen]
      require "#{$knjpath}/thread"
      @listen_thread = Knj::Thread.new do
        begin
          self.listen
        rescue Exception => e
          $stderr.print "#{Knj::Errors.error_str(e)}\n\n" if @debug
          @thread_error = e
        end
      end
    end
  end
  
  def kill_listen
    @listen_thread.kill if @listen_thread
  end
  
  def join
    @listen_thread.join if @listen_thread
    sleep 0.5
    raise @thread_error if @thread_error
  end
  
  #Listens for a new incoming object.
  def listen
    loop do
      str = @in.gets("\n")
      if str == nil
        raise "Socket closed." if @in.closed?
        sleep 0.1
        next
      end
      
      
      data = str.strip.split(":")
      raise "Expected length of 2 or 3 but got: '#{data.length}'.\n#{Knj::Php.print_r(data, true)}" if data.length != 2 and data.length != 3
      
      raise "Invalid ID: '#{data[1]}'." if data[1].to_s.strip.length <= 0
      id = data[1].to_i
      
      raise "Invalid length: '#{data[2]}' (#{str.to_s.strip})." if data[2].to_s.strip.length <= 0
      length = data[2].to_i
      
      $stderr.print "Received ID #{id}.\n" if @debug
      res = @in.read(length)
      $stderr.print "Got content for '#{id}' (#{data[0]}).\n" if @debug
      
      obj = Marshal.load(res)
      
      case data[0]
        when "answer"
          @out_answers[id] = obj
        when "answer_block"
          @blocks[id][:results] << obj
        when "answer_block_end"
          $stderr.print "Answer-block-end received!\n"
          @blocks[id][:block_result] = obj
          @blocks[id][:finished] = true
        when "send"
          Knj::Thread.new do
            result_obj = Knj::Process::Resultobject.new(:process => self, :id => id, :obj => obj)
            
            begin
              @on_rec.call(result_obj)
            rescue Exception => e
              #Error was raised - try to forward it to the server.
              result_obj.answer("type" => "process_error", "class" => e.class.name, "msg" => e.message, "backtrace" => e.backtrace)
            end
          end
        when "send_block"
          Knj::Thread.new do
            result_obj = Knj::Process::Resultobject.new(:process => self, :id => id, :obj => obj)
            block_res = nil
            
            begin
              count = 0
              block_res = @on_rec.call(result_obj) do |answer_block|
                count += 1
                self.answer(id, answer_block, "answer_block")
                
                if count >= 100
                  count = 0
                  
                  loop do
                    answer = self.send(id, nil, "send_block_count")
                    $stderr.print "Answer was: #{answer}\n" if @debug
                    
                    if answer >= 100
                      $stderr.print "More than 100 results are buffered on the other side - wait for them to be handeled before sending more.\n" if @debug
                      sleep 0.05
                    else
                      $stderr.print "Less than 100 results in buffer - send more.\n" if @debug
                      break
                    end
                  end
                end
              end
            rescue Exception => e
              $stderr.print Knj::Errors.error_str(e) if @debug
              #Error was raised - try to forward it to the server.
              result_obj.answer("type" => "process_error", "class" => e.class.name, "msg" => e.message, "backtrace" => e.backtrace)
            ensure
              $stderr.print "Answering with block-end.\n" if @debug
              self.answer(id, block_res, "answer_block_end")
            end
          end
        when "send_block_count"
          if @blocks.key?(obj)
            count = @blocks[obj][:results].length
          else
            count = 0
          end
          
          self.answer(id, count)
        else
          $stderr.print "Unknown command: '#{res[0]}'."
          raise "Unknown command: '#{res[0]}'."
      end
    end
  end
  
  #Answers a send.
  def answer(id, obj, type = "answer")
    $stderr.print "Answering #{id} (#{obj}).\n" if @debug
    str = Marshal.dump(obj)
    
    @out_mutex.synchronize do
      @out.write("#{type}:#{id}:#{str.length}\n#{str}")
    end
  end
  
  #Sends a command to the client.
  def send(obj, wait_for_answer = true, type = "send", &block)
    my_id = nil
    str = Marshal.dump(obj)
    
    @out_mutex.synchronize do
      my_id = @out_count
      @out_count += 1
      $stderr.print "Writing #{my_id} to socket.\n" if @debug
      
      if block
        type = "send_block" if type == "send"
        @blocks[my_id] = {:block => block, :results => [], :finished => false}
      end
      
      @out.write("#{type}:#{my_id}:#{str.length}\n#{str}")
    end
    
    if wait_for_answer
      #Make very, very short sleep, if the result is almost instant this will heavily optimize the speed, because :sleep_answer-argument wont be used.
      sleep 0.00001
      return self.read_answer(my_id)
    end
    
    return {:id => my_id}
  end
  
  #Returns true if an answer with a certain ID has arrived.
  def has_answer?(id)
    return @out_answers.key?(id)
  end
  
  #This is used to call the block with results and remove the results from the array.
  def exec_block_results(id)
    return nil if @blocks[id][:results].empty?
    
    removes = []
    begin
      @blocks[id][:results].each do |res|
        removes << res
        @blocks[id][:block].call(res)
      end
    ensure
      removes.each do |remove|
        @blocks[id][:results].delete(remove)
      end
    end
  end
  
  #Waits for data with a certain ID and returns it when it exists.
  def read_answer(id)
    $stderr.print "Reading answer (#{id}).\n" if @debug
    block_res = @blocks[id]
    
    loop do
      if block_res
        self.exec_block_results(id)
        break if block_res and block_res[:finished]
      else
        break if @out_answers.key?(id)
      end
      
      sleep @args[:sleep_answer]
    end
    
    self.exec_block_results(id) if block_res
    @blocks.delete(id)
    
    ret = @out_answers[id]
    @out_answers.delete(id)
    
    if ret.is_a?(Hash) and ret["type"] == "process_error"
      err = RuntimeError.new(ret["msg"])
      bt = ret["backtrace"] + caller
      err.set_backtrace(bt)
      raise err
    end
    
    $stderr.print "Returning answer (#{id}).\n" if @debug
    return ret
  end
  
  #Closes everything down...
  def destroy
    self.kill_listen
    @err_thread.kill if @err_thread
  end
end

class Knj::Process::Resultobject
  def initialize(args)
    @args = args
    @answered = false
  end
  
  #The object that was passed to the current process/socket.
  def obj
    return @args[:obj]
  end
  
  #Returns the process that spawned this resultobject.
  def process
    return @args[:process]
  end
  
  #Returns the ID this result-object should answer to.
  def id
    return @args[:id]
  end
  
  #Answers the call with the given object.
  def answer(obj)
    @answered = true
    @args[:process].answer(@args[:id], obj)
  end
  
  #Returns true if this result has been answered.
  def answered?
    return @answered
  end
end