require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Autoload" do
  it "Wref" do
    require "#{File.dirname(__FILE__)}/../lib/knj/autoload/wref.rb"
  end
end