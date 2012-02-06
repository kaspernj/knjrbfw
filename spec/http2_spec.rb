require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Http2" do
  it "should be able to do multipart-requests." do
    require "knj/http2"
    require "knj/php"
    
    http = Knj::Http2.new(:host => "www.partyworm.dk")
    resp = http.post_multipart("multipart_test.php", {
      "test_var" => "true"
    })
    
    if resp.body != "multipart-test-test_var=true"
      raise "Expected body to be 'test_var=true' but it wasnt: '#{resp.body}'."
    end
  end
  
  it "it should be able to handle keep-alive correctly" do
    require "knj/http2"
    
    urls = [
      "?show=users_search",
      "?show=users_online",
      "?show=drinksdb",
      "?show=forum&fid=9&tid=1917&page=0"
    ]
    urls = ["robots.txt"]
    
    http = Knj::Http2.new(:host => "www.partyworm.dk", :debug => true)
    0.upto(105) do |count|
      url = urls[rand(urls.size)]
      #print "Doing request #{count} of 200 (#{url}).\n"
      res = http.get(url)
      raise "Body was empty." if res.body.to_s.length <= 0
    end
  end
end