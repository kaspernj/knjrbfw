require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require "knj/strings"

describe "Strings" do
  it "regex" do
    regex = Knj::Strings.regex("/(\d+)/i")
    raise "Regex should be '(?i-mx:(d+))' but wasnt: '#{regex}'." if "#{regex}" != "(?i-mx:(d+))"
    
    regex = Knj::Strings.regex("/\d+/")
    raise "Regex should be '(?-mix:d+)' but wasnt: '#{regex}'." if "#{regex}" != "(?-mix:d+)"
  end
end