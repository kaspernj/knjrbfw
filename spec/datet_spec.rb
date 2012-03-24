require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Datet" do
  it "should be able to make ago-strings" do
    require "knj/datet"
    
    time = Time.at(Time.now.to_i - 5)
    datet = Knj::Datet.in(time)
    res = datet.ago_str
    raise "Expected '5 seconds ago' but got: '#{res}'." if res != "5 seconds ago"
    
    
    time = Time.at(Time.now.to_i - 1800)
    datet = Knj::Datet.in(time)
    res = datet.ago_str
    raise "Expected '30 minutes ago' but got: '#{res}'." if res != "30 minutes ago"
    
    
    time = Time.at(Time.now.to_i - 60)
    datet = Knj::Datet.in(time)
    res = datet.ago_str
    raise "Expected '1 minute ago' but got: '#{res}'." if res != "1 minute ago"
    
    
    time = Time.at(Time.now.to_i - 48 * 3600)
    datet = Knj::Datet.in(time)
    res = datet.ago_str
    raise "Expected '48 hours ago' but got: '#{res}'." if res != "48 hours ago"
  end
end