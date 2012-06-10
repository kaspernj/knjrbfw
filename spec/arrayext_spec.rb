require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "ArrayExt" do
  it "should be able to make ago-strings" do
    arr = [1, 2]
    Knj::ArrayExt.force_no_cols(:arr => arr, :no => 1)
    raise "Expected length of 1 but got: #{arr.length}" if arr.length != 1
    raise "Expected element to be 1 but it wasnt: #{arr[0]}" if arr[0] != 1
  end
end