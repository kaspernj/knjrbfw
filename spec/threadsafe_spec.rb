require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Threadsafe" do
  it "should be able to spawn threadsafe proxy-objects" do
    require "knjrbfw"
    
    arr = Knj::Threadsafe::Proxy.new(:obj => {})
    
    0.upto(5) do |i|
      arr[i] = i
    end
    
    Knj::Thread.new do
      arr.each do |key, val|
        res = key + val
        sleep 0.1
      end
    end
    
    5.upto(10) do |i|
      arr[i] = i
      sleep 0.1
    end
  end
  
  it "should be able to spawn special classes" do
    require "knjrbfw"
    
    #Create new synchronized hash.
    arr = Knj::Threadsafe::Synced_hash.new
    
    #Make sure we get the right results.
    arr[1] = 2
    
    res = arr[1]
    raise "Expected 2 but got '#{res}'." if res != 2
    
    #Set some values to test with.
    0.upto(5) do |i|
      arr[i] = i
    end
    
    #Try to call through each through a thread and then also try to set new values, which normally would crash the hash.
    Knj::Thread.new do
      arr.each do |key, val|
        res = key + val
        sleep 0.1
      end
    end
    
    #This should not crash it, since they should wait for each other.
    5.upto(10) do |i|
      arr[i] = i
      sleep 0.1
    end
  end
end