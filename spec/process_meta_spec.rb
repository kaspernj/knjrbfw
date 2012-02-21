require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Process_meta" do
  it "should be able to start a server and a client" do
    require "knj/autoload"
    
    #Start the activity.
    $process_meta = Knj::Process_meta.new("debug" => false, "debug_err" => true)
  end
  
  it "should be able to do various operations" do
    #Test that breaking a block wont continue to run in the process.
    $process_meta.str_eval("
      class Testclass
        attr_reader :last_num
        
        def initialize
          @num = 0
        end
        
        def test_block
          @num.upto(10) do |i|
            @last_num = i
            yield(i)
          end
        end
      end
    ")
    
    proxy_obj = $process_meta.new(:Testclass)
    proxy_obj2 = $process_meta.new(:Testclass)
    proxy_obj3 = $process_meta.new(:Testclass)
    
    $ids = []
    $ids << proxy_obj.__id__
    $ids << proxy_obj2.__id__
    $ids << proxy_obj3.__id__
    
    proxy_obj.test_block do |i|
      if i == 5
        break
      end
    end
    
    last_num = proxy_obj.last_num
    raise "Expected last num to be 5 but it wasnt: '#{last_num}'." if last_num != 5
    
    #Somehow define_finalizer is always one behind, so we have to do funny one here.
    ObjectSpace.define_finalizer(self, $process_meta.method(:proxy_finalizer))
  end
  
  it "should be able to do more" do
    GC.start
    
    #Its difficult to test this on JRuby.
    if RUBY_ENGINE != "jruby"
      count = 0
      $ids.each do |id|
        count += 1
        raise "The object should no longer exist but it does: #{count}." if $process_meta.proxy_has?(id)
      end
    end
    
    
    #Spawn a test-object - a string - with a variable-name.
    proxy_obj = $process_meta.spawn_object(:String, "my_test_var", "Kasper")
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
    
    
    
    #Try to define an integer and run upto with a block.
    proxy_int = $process_meta.spawn_object(:Integer, nil, 5)
    expect = 5
    proxy_int.upto(1000) do |i|
      raise "Expected '#{expect}' but got: '#{i}'." if i != expect
      expect += 1
    end
    
    #Ensure the expected has actually been increased by running the block.
    raise "Expected end-result of 11 but got: '#{expect}'." if expect != 1001
    
    
    proxy_int._process_meta_block_buffer_use = true
    expect = 5
    proxy_int.upto(10000) do |i|
      raise "Expected '#{expect}' but got: '#{i}'." if i != expect
      expect += 1
    end
    
    
    #Ensure the expected has actually been increased by running the block.
    raise "Expected end-result of 11 but got: '#{expect}'." if expect != 10001
    
    #Try to unset an object.
    proxy_obj._process_meta_unset
    proxy_int._process_meta_unset
  end
  
  it "should be able to do slow block-results in JRuby." do
    $process_meta.str_eval("
      class Kaspertest
        def kaspertest
          8.upto(12) do |i|
            yield(i)
            sleep 0.5
          end
        end
      end
      
      nil
    ")
    
    Timeout.timeout(5) do
      expect = 8
      $process_meta.static("Kaspertest", "kaspertest") do |count|
        raise "Expected '#{expect}' but got: '#{count}'."
        expect += 1
      end
      
      raise "Expected '13' but got: '#{expect}'."
    end
  end
  
  it "should be able to be destroyed." do
    #Destroy the process-meta which should stop the process.
    $process_meta.destroy
  end
end