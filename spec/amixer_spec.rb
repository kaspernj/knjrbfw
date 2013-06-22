require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Amixer" do
  it "should load by using autoload" do
    if Knj::Os.os == "linux"
      require "knjrbfw"
      $amixer = Knj::Amixer.new
    end
  end
  
  it "should register various devices" do
    if Knj::Os.os == "linux"
      $devices = $amixer.devices
    end
  end
  
  it "should register various mixers and do various operations on them" do
    if Knj::Os.os == "linux"
      $devices.each do |name, device|
        mixers = device.mixers
        
        if device.active?(:stream => "PLAYBACK")
          mixers.each do |name, mixer|
            next if !mixer.volume?
            mixer.vol_add -5
            mixer.vol_add 3
          end
        end
      end
    end
  end
end