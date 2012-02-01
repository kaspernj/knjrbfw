require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Process_meta" do
  it "should be able to start a server and a client" do
    require "knj/autoload"
    
    #Start the activity.
    process_eval = Knj::Process_meta.new
    
    #Spawn a test-object - a string.
    proxy_obj = process_eval.spawn_object(:String, "my_test_var", "Kasper")
    raise "to_s should return 'Kasper' but didnt: '#{proxy_obj.to_s}'." if proxy_obj.to_s != "Kasper"
    
    #Stress it a little by doing 500 calls.
    0.upto(500) do
      res = proxy_obj.slice(0, 3)
      raise "Expected output was: 'Kas' but wasnt: '#{res}'." if res != "Kas"
    end
    
    #Do a lot of calls at the same time to test thread-safety.
    threads = []
    0.upto(10) do |i|
      should_return = "Kasper".slice(0, i)
      threads << Knj::Thread.new do
        0.upto(500) do
          res = proxy_obj.slice(0, i)
          raise "Should return: '#{should_return}' but didnt: '#{res}'." if res != should_return
        end
      end
    end
    
    threads.each do |thread|
      thread.join
    end
    
    #Try to unset an object.
    proxy_obj.process_eval_unset
    
    #Destroy the process-eval which should stop the process.
    process_eval.destroy
  end
end