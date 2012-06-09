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
    raise "Expected '2 days ago' but got: '#{res}'." if res != "2 days ago"
  end
  
  #From "knjrbfw_spec.rb".
  it "should be able to parse various date formats." do
    date = Knj::Datet.in("2011-07-09 00:00:00 UTC")
    date = Knj::Datet.in("1985-06-17 01:00:00")
    date = Knj::Datet.in("1985-06-17")
    date = Knj::Datet.in("17/06 1985")
    
    raise "Couldnt register type 1 nullstamp." if !Knj::Datet.is_nullstamp?("0000-00-00")
    raise "Couldnt register type 2 nullstamp." if !Knj::Datet.is_nullstamp?("0000-00-00 00:00:00")
    raise "Registered nullstamp on valid date." if Knj::Datet.is_nullstamp?("1985-06-17")
    raise "Registered nullstamp on valid date." if Knj::Datet.is_nullstamp?("1985-06-17 10:30:00")
    
    date = Knj::Datet.in("2011-07-09 13:05:04 +0200")
    ltime = date.localtime_str
    
    #if RUBY_VERSION.slice(0, 3) == "1.9"
    #  if ltime != date.time.localtime
    #    raise "Calculated localtime (#{ltime}) was not the same as the real Time-localtime (#{date.time.localtime})."
    #  end
    #end
    
    if ltime != "2011-07-09 13:05:04 +0200"
      raise "Datet didnt return expected result: '#{ltime}'."
    end
  end
  
  it "should be able to compare dates" do
    date1 = Knj::Datet.in("17/06 1985")
    date2 = Knj::Datet.in("18/06 1985")
    date3 = Knj::Datet.in("17/06 1985")
    
    raise "Date1 was wrongly higher than date2." if date1 > date2
    
    if date2 > date1
      #do nothing.
    else
      raise "Date2 was wrongly not higher than date1."
    end
    
    raise "Date1 was wrongly not the same as date3." if date1 != date3
    raise "Date1 was the same as date2?" if date1 == date2
  end
end