require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Web" do
  it "should be able to parse url and generate hashes" do
    require "knj/php"
    require "knj/web"
    
    url = "first=test&#{Knj::Web.urlenc("second[trala][]")}=1&#{Knj::Web.urlenc("second[trala][]")}=2&#{Knj::Web.urlenc("second[trala][]")}=3"
    res = Knj::Web.parse_urlquery(url)
    
    raise "Couldnt parse 'first'-element." if res["first"] != "test"
    raise "'second' wasnt a hash or contained invalid amounr of elements." if !res["second"].is_a?(Hash) or res["second"].length != 1
    raise "'trala' in 'second' wasnt a hash or contained invalid amount of elements." if !res["second"]["trala"].is_a?(Hash) or res["second"]["trala"].length != 3
    raise "'trala' in 'second' didnt contain the right elements." if res["second"]["trala"]["0"] != "1" or res["second"]["trala"]["1"] != "2" or res["second"]["trala"]["2"] != "3"
  end
  
  #Moved from "knjrbfw_spec.rb".
  it "should be able to use alert and back." do
    Knj::Web.alert("Trala")
    
    begin
      Knj::Web.back
      raise "It should have called exit which it didnt."
    rescue SystemExit
      #ignore.
    end
    
    begin
      Knj::Web.redirect("?show=test")
      raise "It should have called exit which it didnt."
    rescue SystemExit
      #ignore.
    end
  end
  
  it "should be able to properly parse 'Set-Cookie' headers." do
    data = Knj::Web.parse_set_cookies("TestCookie=TestValue+; Expires=Fri, 05 Aug 2011 10:58:17 GMT; Path=\n")
    
    raise "No data returned?" if !data or !data.respond_to?(:length)
    raise "Wrong number of cookies returned: '#{data.length}'." if data.length != 1
    
    raise "Unexpected name: '#{data[0]["name"]}'." if data[0]["name"] != "TestCookie"
    raise "Unexpected value: '#{data[0]["value"]}'." if data[0]["value"] != "TestValue "
    raise "Unexpected path: '#{data[0]["path"]}'." if data[0]["path"] != ""
    raise "Unexpected expire:' #{data[0]["expire"]}'." if data[0]["expires"] != "Fri, 05 Aug 2011 10:58:17 GMT"
  end
  
  it "should be able to execute various forms of Web.input methods." do
    html = Knj::Web.inputs([{
      :title => "Test 1",
      :name => :textest1,
      :type => :text,
      :default => "hmm",
      :value => "trala"
    },{
      :title => "Test 2",
      :name => :chetest2,
      :type => :checkbox,
      :default => true
    },{
      :title => "Test 4",
      :name => :textest4,
      :type => :textarea,
      :height => 300,
      :default => "Hmm",
      :value => "Trala"
    },{
      :title => "Test 5",
      :name => :filetest5,
      :type => :file
    },{
      :title => "Test 6",
      :type => :info,
      :value => "Argh"
    }])
  end
end