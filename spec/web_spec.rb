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
    raise "'trala' in 'second' didnt contain the right elements." if res["second"]["trala"][0] != "1" or res["second"]["trala"][1] != "2" or res["second"]["trala"][2] != "3"
  end
end