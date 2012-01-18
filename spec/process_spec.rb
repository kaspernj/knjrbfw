require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Process" do
  it "should be able to start a server and a client" do
    require "knj/autoload"
    
    tcp_server = TCPServer.new("0.0.0.0", 15678)
    conn_client = TCPSocket.new("localhost", 15678)
    conn_server = tcp_server.accept
    
    $process_server = Knj::Process.new(
      :in => conn_server,
      :out => conn_server,
      :debug => false,
      :listen => true,
      :on_rec => proc{|d|
        if d.obj == "hello server"
          d.answer("hello back client")
        elsif match = d.obj.match(/^test (\d+)$/)
          print "Answering #{match[1]}\n"
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
      :on_rec => proc{|d|
        if d.obj == "hello client"
          d.answer("hello back server")
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
    
    Timeout.timeout(15) do
      0.upto(1000) do |count|
        print "Testing #{count}\n"
        answer = $process_client.send("test #{count}")
        match = answer.match(/^testanswer (\d+)$/)
        raise "Unexpected answer: '#{answer}'." if !match
      end
    end
  end
end