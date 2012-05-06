require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Wref" do
  it "should load by using autoload" do
    require "knjrbfw"
    
    #Autoload wref-map.
    Knj::Wref_map
  end
end