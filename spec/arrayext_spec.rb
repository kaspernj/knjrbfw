require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "ArrayExt" do
  it "should be able to do powersets" do
    ps = Knj::ArrayExt.powerset(:arr => [1, 2, 3, 4]).to_a
    raise "Expected length of 16 but it wasnt: #{ps.length}" if ps.length != 16
    
    ite = 0
    Knj::ArrayExt.powerset(:arr => [1, 2, 3, 4]) do |arr|
      ite += 1
    end
    
    raise "Expected block to be executed 16 times but it wasnt: #{ite}" if ite != 16
  end
  
  it "should be able to divide arrays" do
    arr = [1, 2, 3, 4, 6, 7, 8, 9, 15, 16, 17, 18]
    res = Knj::ArrayExt.divide(:arr => arr) do |a, b|
      if (b - a) > 1
        false
      else
        true
      end
    end
    
    raise "Expected length of 3 but it wasnt: #{res.length}" if res.length != 3
    raise "Expected length of 4 but it wasnt: #{res[0].length}" if res[0].length != 4
    raise "Expected length of 3 but it wasnt: #{res[1].length}" if res[1].length != 3
    raise "Expected length of 3 but it wasnt: #{res[2].length}" if res[2].length != 3
  end
  
  it "should be able to make ago-strings" do
    arr = [1, 2]
    Knj::ArrayExt.force_no_cols(:arr => arr, :no => 1)
    raise "Expected length of 1 but got: #{arr.length}" if arr.length != 1
    raise "Expected element to be 1 but it wasnt: #{arr[0]}" if arr[0] != 1
    
    Knj::ArrayExt.force_no_cols(:arr => arr, :no => 3, :empty => "test")
    raise "Expected length of 3 but got: #{arr.lengtj}" if arr.length != 3
    raise "Expected element 2 to be 'test' but it wasnt: #{arr[2]}" if arr[2] != "test"
  end
end