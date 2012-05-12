require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Process" do
  it "should be able to start a server and a client" do
    require "timeout"
    
    tcp_server = TCPServer.new("0.0.0.0", 15678)
    conn_client = TCPSocket.new("localhost", 15678)
    conn_server = tcp_server.accept
    
    answers = {}
    
    $process_server = Knj::Process.new(
      :in => conn_server,
      :out => conn_server,
      :debug => false,
      :listen => true,
      :on_rec => proc{|d|
        if d.obj == "hello server"
          d.answer("hello back client")
        elsif match = d.obj.match(/^test (\d+)$/)
          d.answer("testanswer #{match[1]}")
        else
          raise "Received unknown object: '#{d.obj}'."
        end
      }
    )
    
    $process_client = Knj::Process.new(
      :in => conn_client,
      :out => conn_client,
      :debug => false,
      :listen => true,
      :on_rec => proc{|d, &block|
        if d.obj == "hello client"
          d.answer("hello back server")
        elsif d.obj == "test_block"
          raise "No block was given." if !block
          0.upto(100) do |i|
            #$stderr.print "Calling block with: #{i}\n"
            block.call(i)
          end
          
          d.answer("ok")
        else
          raise "Received unknown object: '#{d.obj}'."
        end
      }
    )
    
    Timeout.timeout(1) do
      answer = $process_server.send("hello client")
      raise "Unexpected answer: '#{answer}'." if answer != "hello back server"
    end
    
    Timeout.timeout(1) do
      answer = $process_client.send("hello server")
      raise "Unexpected answer: '#{answer}'." if answer != "hello back client"
    end
    
    #Stress it by doing 1000 requests.
    if RUBY_ENGINE == "jruby"
      tout = 7
    else
      tout = 2
    end
    
    Timeout.timeout(tout) do
      0.upto(1000) do |count|
        #$stderr.print "Testing #{count}\n"
        answer = $process_client.send("test #{count}")
        match = answer.match(/^testanswer (\d+)$/)
        raise "Unexpected answer: '#{answer}'." if !match
      end
    end
    
    
    #Run a test block.
    expect = 0
    $process_server.send("test_block") do |ele|
      #$stderr.print "test_block: #{ele}\n"
      raise "Expected '#{expect}' but got: '#{ele}'." if ele != expect
      expect += 1
    end
    
    
    #Run several test blocks at the same time.
    threads = []
    results = {} #this can be used for debugging.
    
    0.upto(10) do |thread_id|
      threads << Knj::Thread.new do
        myres = []
        expect_thread = 0
        $process_server.send("test_block") do |ele|
          #$stderr.print "test_block: #{ele}\n"
          myres << [ele, expect_thread]
          raise "Expected '#{expect_thread}' but got: '#{ele}'." if ele != expect_thread
          expect_thread += 1
        end
        
        results[thread_id] = myres
      end
    end
    
    threads.each do |thread|
      thread.join
    end
    
    #this can be used for debugging.
    #Knj::Php.print_r(results)
  end
end