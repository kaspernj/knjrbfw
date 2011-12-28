require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Amixer" do
  it "should load by using autoload" do
    require "knjrbfw"
    require "knj/autoload"
    
    $amixer = Knj::Amixer.new
  end
  
  it "should register various devices" do
    $devices = $amixer.devices
  end
  
  it "should register various mixers and do various operations on them" do
    $devices.each do |name, device|
      mixers = device.mixers
      
      if device.active?(:stream => "PLAYBACK")
        mixers.each do |name, mixer|
          next if !mixer.volume?
          mixer.vol_add -5
        end
      end
    end
  end
end