require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Php" do
  it "explode" do
    require "knj/php"
    
    teststr = "1;2;3"
    arr = Knj::Php.explode(";", teststr)
    
    raise "Invalid length." if arr.length != 3
    raise "Invalid first." if arr[0] != "1"
    raise "Invalid second." if arr[1] != "2"
    raise "Invalid third." if arr[2] != "3"
  end
  
  it "is_numeric" do
    require "knj/php"
    
    raise "Failed." if !Knj::Php.is_numeric(123)
    raise "Failed." if !Knj::Php.is_numeric("123")
    raise "Failed." if Knj::Php.is_numeric("kasper123")
    raise "Failed." if Knj::Php.is_numeric("123kasper")
    raise "Failed." if !Knj::Php.is_numeric(123.12)
    raise "Failed." if !Knj::Php.is_numeric("123.12")
  end
  
  it "number_format" do
    tests = {
      Knj::Php.number_format(123123.12, 3, ",", ".") => "123.123,120",
      Knj::Php.number_format(123123.12, 4, ".", ",") => "123,123.1200",
      Knj::Php.number_format(-123123.12, 2, ",", ".") => "-123.123,12",
      Knj::Php.number_format(-120, 2, ",", ".") => "-120,00",
      Knj::Php.number_format(-12, 2, ".", ",") => "-12.00"
    }
    
    tests.each do |key, val|
      if key != val
        raise "Key was not the same as value (#{key}) (#{val})."
      end
    end
  end
  
  it "parse_str" do
    require "knj/php"
    require "knj/web"
    
    teststr = "first=value&arr[]=foo+bar&arr[]=baz&hash[trala]=hmm&hash[trala2]=wtf"
    
    hash = {}
    Knj::Php.parse_str(teststr, hash)
    
    raise "Invalid value for first." if hash["first"] != "value"
    raise "Invalid value for first in arr." if hash["arr"]["0"] != "foo bar"
    raise "Invalid value for second in arr." if hash["arr"]["1"] != "baz"
    raise "Invalid value for hash-trala." if hash["hash"]["trala"] != "hmm"
    raise "Invalid value for hash-trala2." if hash["hash"]["trala2"] != "wtf"
  end
end