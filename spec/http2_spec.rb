require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Http2" do
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