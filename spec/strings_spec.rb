require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require "knj/strings"
require "knj/errors"

describe "Strings" do
  it "regex" do
    regex = Knj::Strings.regex("/(\d+)/i")
    raise "Regex should be '(?i-mx:(d+))' but wasnt: '#{regex}'." if "#{regex}" != "(?i-mx:(d+))"
    
    regex = Knj::Strings.regex("/\d+/")
    raise "Regex should be '(?-mix:d+)' but wasnt: '#{regex}'." if "#{regex}" != "(?-mix:d+)"
    
    begin
      regex = Knj::Strings.regex("/\d+/U")
      raise "Ruby doesnt support the U-modifier - an exception should be thrown!"
    rescue ArgumentError
      #this should happen - Ruby doesnt support U-modifier...
    end
    
    res = Knj::Strings.is_regex?("Kasper")
    raise "Expected res to be false but it wasnt." if res
    
    res = Knj::Strings.is_regex?("/^Kasper$/")
    raise "Expected res to be true but it wasnt." if !res
  end
  
  it "secs_to_human_time_str" do
    res = Knj::Strings.secs_to_human_time_str(3695)
    raise "Expected '01:01:35' but got: '#{res}'." if res != "01:01:35"
  end
end