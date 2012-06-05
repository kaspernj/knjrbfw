require "#{$knjpath}errors"
require "#{$knjpath}thread"

#This class is able to control communicate with another Ruby-process also running Knj::Process.
class Knj::Process
  attr_reader :blocks, :blocks_send
  
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
    
    #Used when this process is trying to receive block-results from the subprocess.
    @blocks = {}
    
    #Used when the other process is trying to receive block-results from this object.
    @blocks_send = {}
    
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
          
          #Try to break out of loop - the process has been destroyed.
          break if (!@out_mutex and str.to_s.strip.length <= 0) or (@args and @args[:err] and @args[:err].closed?)
        end
      end
    end
    
    if @args[:listen]
      require "#{$knjpath}/thread"
      @listen_thread = Knj::Thread.new do
        begin
          self.listen
        rescue => e
          $stderr.print "#{Knj::Errors.error_str(e)}\n\n" if @debug
          @thread_error = e
        end
      end
    end
  end
  
  #Kills the listen-thread.
  def kill_listen
    @listen_thread.kill if @listen_thread
  end
  
  #Joins the listen-thread and the error-thread.
  def join
    @listen_thread.join if @listen_thread
    sleep 0.5
    raise @thread_error if @thread_error
  end
  
  #Listens for a new incoming object.
  def listen
    loop do
      self.listen_loop
      
      #Break out if something is wrong.
      break if !@out_mutex or (@in and @in.closed?) or (@out and @out.closed?)
    end
  end
  
  #This method is called by listen on every loop.
  def listen_loop
    $stderr.print "listen-loop called.\n" if @debug
    
    str = @in.gets("\n")
    if str == nil
      raise "Socket closed." if @in.closed?
      sleep 0.1
      return nil
    end
    
    
    data = str.strip.split(":")
    raise "Expected length of 2 or 3 but got: '#{data.length}'.\n#{data}" if data.length != 2 and data.length != 3
    
    raise "Invalid ID: '#{data[1]}'." if data[1].to_s.strip.length <= 0
    id = data[1].to_i
    
    raise "Invalid length: '#{data[2]}' (#{str.to_s.strip})." if data[2].to_s.strip.length <= 0
    length = data[2].to_i
    
    $stderr.print "Received ID #{id}.\n" if @debug
    res = @in.read(length)
    
    begin
      obj = Marshal.load(res)
      $stderr.print "Got content for '#{id}' (#{data[0]}).\n" if @debug
      
      case data[0]
        when "answer"
          #raise "Already have answer for '#{id}'." if @out_answers.key?(id)
          @out_answers[id] = obj
        when "answer_block"
          @blocks[id][:mutex].synchronize do
            @blocks[id][:results] += obj
          end
        when "answer_block_end"
          $stderr.print "Answer-block-end received!\n" if @debug
          @blocks[id][:block_result] = obj
          @blocks[id][:finished] = true
        when "send"
          Knj::Thread.new do
            result_obj = Knj::Process::Resultobject.new(:process => self, :id => id, :obj => obj)
            
            begin
              @on_rec.call(result_obj)
            rescue SystemExit, Interrupt => e
              raise e
            rescue => e
              #Error was raised - try to forward it to the server.
              result_obj.answer("type" => "process_error", "class" => e.class.name, "msg" => e.message, "backtrace" => e.backtrace)
            end
          end
        when "send_block"
          result_obj = Knj::Process::Resultobject.new(:process => self, :id => id, :obj => obj)
          @blocks_send[id] = {:result_obj => result_obj, :waiting_for_result => false}
          
          @blocks_send[id][:enum] = Enumerator.new do |y|
            @on_rec.call(result_obj) do |answer_block|
              $stderr.print "Running enum-block for #{answer_block}\n" if @debug
              
              #Block has ended on hosts side - break out of block-loop.
              break if !@blocks_send.key?(id)
              
              #Throw the result at the block running.
              y << answer_block
              
              #This is to prevent the block-loop from running again, until host has confirmed it wants another result.
              dobreak = false
              
              loop do
                #Block has ended on hosts-side - break of out block-loop.
                if !@blocks_send.key?(id)
                  dobreak = true
                  break
                end
                
                #If waiting for result then release the loop and return another result.
                if @blocks_send[id][:waiting_for_result]
                  @blocks_send[id][:waiting_for_result] = false
                  break
                end
                
                #Wait a little with checking for another result to not use 100% CPU.
                sleep 0.01
              end
              
              #The block-loop should not run again - it has been prematurely interrupted on the host-side.
              break if dobreak
            end
          end
        when "send_block_res"
          begin
            #The host wants another result. Set the 'waiting-for-result' and wait for the enumerator to run. Then return result from enumerator (code is right above here).
            @blocks_send[obj][:waiting_for_result] = true
            res = @blocks_send[obj][:enum].next
            self.answer(id, {"result" => res})
          rescue StopIteration
            self.answer(id, "StopIteration")
          end
        when "send_block_end"
          if @blocks_send.key?(obj)
            enum = @blocks_send[obj][:enum]
            @blocks_send.delete(obj)
            
            begin
              enum.next if enum #this has to be called to stop Enumerator from blocking...
            rescue StopIteration
              #do nothing.
            end
          end
          
          self.answer(id, "ok")
        when "send_block_buffer"
          Knj::Thread.new do
            result_obj = Knj::Process::Resultobject.new(:process => self, :id => id, :obj => obj)
            block_res = nil
            buffer_done = false
            
            begin
              buffer_answers = Knj::Threadsafe.std_array #JRuby needs the threadsafety.
              buffer_thread = Knj::Thread.new do
                loop do
                  arr = buffer_answers.shift(200)
                  
                  if !arr.empty?
                    $stderr.print "Sending: #{arr.length} results.\n" if @debug
                    self.answer(id, arr, "answer_block")
                  else
                    $stderr.print "Waiting for buffer-stuff (#{arr.length}, #{buffer_done}).\n" if @debug
                    sleep 0.05
                  end
                  
                  break if buffer_done and buffer_answers.empty?
                end
              end
              
              begin
                begin
                  count = 0
                  block_res = @on_rec.call(result_obj) do |answer_block|
                    loop do
                      if buffer_answers.length > 1000
                        $stderr.print "Buffer is more than 1000 - sleeping and tries again in 0.05 sec.\n" if @debug
                        sleep 0.05
                      else
                        break
                      end
                    end
                    
                    count += 1
                    buffer_answers << answer_block
                    
                    if count >= 100
                      count = 0
                      
                      loop do
                        answer = self.send("obj" => id, "type" => "send_block_count")
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
                ensure
                  buffer_done = true
                end
              ensure
                buffer_thread.join
              end
            rescue => e
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
          $stderr.print "Unknown command: '#{data[0]}'."
          raise "Unknown command: '#{data[0]}'."
      end
    rescue => e
      $stderr.print Knj::Errors.error_str(e) if @debug
      #Error was raised - try to forward it to the server.
      result_obj = Knj::Process::Resultobject.new(:process => self, :id => id, :obj => obj)
      result_obj.answer("type" => "process_error", "class" => e.class.name, "msg" => e.message, "backtrace" => e.backtrace)
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
  def send(args, &block)
    args = {"obj" => args} if !args.is_a?(Hash)
    
    my_id = nil
    raise "No 'obj' was given." if !args["obj"]
    str = Marshal.dump(args["obj"])
    
    if args.key?("type")
      type = args["type"]
    else
      type = "send"
    end
    
    raise "Invalid type: '#{type}'." if type.to_s.strip.length <= 0
    args["wait_for_answer"] = true if !args.key?("wait_for_answer")
    
    @out_mutex.synchronize do
      my_id = @out_count
      @out_count += 1
      
      if block
        if type == "send"
          if args["buffer_use"]
            type = "send_block_buffer"
            @blocks[my_id] = {:block => block, :results => [], :finished => false, :buffer => args["buffer_use"], :mutex => Mutex.new}
          else
            type = "send_block"
          end
        end
      end
      
      $stderr.print "Writing #{type}:#{my_id}:#{args["obj"]} to socket.\n" if @debug
      @out.write("#{type}:#{my_id}:#{str.length}\n#{str}")
    end
    
    #If block is broken it might never give us control to return anything - thats why we use ensure.
    begin
      if type == "send_block"
        loop do
          res = self.send("obj" => my_id, "type" => "send_block_res")
          
          if res == "StopIteration"
            break
          elsif res.is_a?(Hash) and res.key?("result")
            #do nothing.
          else
            raise "Unknown result: '#{res}'."
          end
          
          block.call(res["result"])
        end
      end
    ensure
      #Tell the subprocess we are done with the block (if break, exceptions or anything else like that was used).
      if type == "send_block"
        res = self.send("obj" => my_id, "type" => "send_block_end")
        raise "Unknown result: '#{res}'." if res != "ok"
      end
      
      if args["wait_for_answer"]
        #Make very, very short sleep, if the result is almost instant this will heavily optimize the speed, because :sleep_answer-argument wont be used.
        sleep 0.00001
        return self.read_answer(my_id)
      end
      
      return {:id => my_id}
    end
  end
  
  #Returns true if an answer with a certain ID has arrived.
  def has_answer?(id)
    return @out_answers.key?(id)
  end
  
  #This is used to call the block with results and remove the results from the array.
  def exec_block_results(id)
    return nil if @blocks[id][:results].empty?
    
    removes = []
    @blocks[id][:mutex].synchronize do
      results = @blocks[id][:results]
      @blocks[id][:results] = []
      
      results.each do |res|
        removes << res
        @blocks[id][:block].call(res)
      end
    end
  end
  
  #Waits for data with a certain ID and returns it when it exists.
  def read_answer(id)
    $stderr.print "Reading answer (#{id}).\n" if @debug
    block_res = @blocks[id]
    $stderr.print "Answer is block for #{id} #{block_res}\n" if @debug and block_res
    
    loop do
      raise "Process destroyed." if !@out_answers
      
      if block_res
        self.exec_block_results(id)
        break if block_res and block_res[:finished]
      else
        break if @out_answers.key?(id)
      end
      
      sleep @args[:sleep_answer]
    end
    
    if block_res
      self.exec_block_results(id)
      @blocks.delete(id)
    end
    
    ret = @out_answers[id]
    @out_answers.delete(id)
    
    if ret.is_a?(Hash) and ret["type"] == "process_error"
      $stderr.print "Process-error - begin generating error...\n" if @debug
      err = RuntimeError.new(ret["msg"])
      bt = []
      ret["backtrace"].each do |subproc_bt|
        bt << "Subprocess: #{subproc_bt}"
      end
      
      caller.each do |proc_bt|
        bt << proc_bt
      end
      
      err.set_backtrace(bt)
      
      $stderr.print Knj::Errors.error_str(err) if @debug
      raise err
    end
    
    $stderr.print "Returning answer (#{id}).\n" if @debug
    return ret
  end
  
  #Closes everything down...
  def destroy
    self.kill_listen
    @err_thread.kill if @err_thread
    @out_answers = nil
    @out_mutex = nil
  end
end

class Knj::Process::Resultobject
  attr_reader :args
  
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