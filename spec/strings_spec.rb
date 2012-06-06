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
    rescue Knj::Errors::InvalidData
      #this should happen - Ruby doesnt support U-modifier...
    end
    
    res = Knj::Strings.is_regex?("Kasper")
    raise "Expected res to be false but it wasnt." if res
  end
end