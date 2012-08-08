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
    
    regex = Knj::Strings.regex("/(\\d{6})$/")
    res = "FNR. 7213820".match(regex)
    raise "Not matched." if !res
    raise "Expected result 1 to be '213820' but it wasnt: '#{res[1]}'." if res[1] != "213820"
    
    res = Knj::Strings.is_regex?("Kasper")
    raise "Expected res to be false but it wasnt." if res
    
    res = Knj::Strings.is_regex?("/^Kasper$/")
    raise "Expected res to be true but it wasnt." if !res
  end
  
  it "secs_to_human_time_str" do
    res = Knj::Strings.secs_to_human_time_str(3695)
    raise "Expected '01:01:35' but got: '#{res}'." if res != "01:01:35"
    
    secs = Knj::Strings.human_time_str_to_secs("01:30:30")
    raise "Expected secs to be 5430 but it was #{secs}" if secs != 5430
    
    secs = Knj::Strings.human_time_str_to_secs("01:30")
    raise "Expected secs to be 5400 but it was #{secs}" if secs != 5400
  end
  
  it "secs_to_human_short_time" do
    res = Knj::Strings.secs_to_human_short_time(3700)
    raise "Expected '1.0t' but got '#{res}'." if res != "1.0t"
    
    res = Knj::Strings.secs_to_human_short_time(57)
    raise "Expected '57s' but got '#{res}'." if res != "57s"
    
    res = Knj::Strings.secs_to_human_short_time(185)
    raise "Expected '3m' but got '#{res}'." if res != "3m"
    
    res = Knj::Strings.secs_to_human_short_time(57, :secs => false)
    raise "Expected '0m' but got '#{res}'." if res != "0m"
    
    res = Knj::Strings.secs_to_human_short_time(120, :mins => false)
    raise "Expected '0.0t' but got '#{res}'." if res != "0.0t"
  end
end