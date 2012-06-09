require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Http2" do
  it "should be able to recursively parse post-data-hashes." do
    require "knj/http2"
    
    res = Knj::Http2.post_convert_data(
      "test1" => "test2"
    )
    raise "Expected 'test1=test2' but got: '#{res}'." if res != "test1=test2"
    
    res = Knj::Http2.post_convert_data(
      "test1" => [1, 2, 3]
    )
    raise "Expected 'test1%5B0%5D=1test1%5B1%5D=2test1%5B2%5D=3' but got: '#{res}'." if res != "test1%5B0%5D=1test1%5B1%5D=2test1%5B2%5D=3"
    
    res = Knj::Http2.post_convert_data(
      "test1" => {
        "order" => {
          [:Bnet_profile, "profile_id"] => 5
        }
      }
    )
    raise "Expected 'test1%5Border%5D%5B%5B%3ABnet_profile%2C+%22profile_id%22%5D%5D=5' but got: '#{res}'." if res != "test1%5Border%5D%5B%5B%3ABnet_profile%2C+%22profile_id%22%5D%5D=5"
  end
  
  it "should be able to do normal post-requests." do
    require "json"
    
    #Test posting keep-alive and advanced post-data.
    Knj::Http2.new(:host => "www.partyworm.dk") do |http|
      0.upto(5) do
        resp = http.get("multipart_test.php")
        
        resp = http.post("multipart_test.php?choice=post-test", {
          "val1" => "test1",
          "val2" => "test2",
          "val3" => [
            "test3"
          ],
          "val4" => {
            "val5" => "test5"
          },
          "val6" => {
            "val7" => [
              {
                "val8" => "test8"
              }
            ]
          }
        })
        res = JSON.parse(resp.body)
        
        raise "Expected 'res' to be a hash." if !res.is_a?(Hash)
        raise "Error 1" if res["val1"] != "test1"
        raise "Error 2" if res["val2"] != "test2"
        raise "Error 3" if !res["val3"] or res["val3"][0] != "test3"
        raise "Error 4" if res["val4"]["val5"] != "test5"
        raise "Error 5" if res["val6"]["val7"][0]["val8"] != "test8"
      end
    end
  end
  
  it "should be able to do multipart-requests and keep-alive when using multipart." do
    Knj::Http2.new(:host => "www.partyworm.dk", :follow_redirects => false) do |http|
      0.upto(5) do
        resp = http.post_multipart("multipart_test.php", {
          "test_var" => "true"
        })
        
        if resp.body != "multipart-test-test_var=true"
          raise "Expected body to be 'test_var=true' but it wasnt: '#{resp.body}'."
        end
      end
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
    
    http = Knj::Http2.new(:host => "www.partyworm.dk", :debug => false)
    0.upto(105) do |count|
      url = urls[rand(urls.size)]
      #print "Doing request #{count} of 200 (#{url}).\n"
      #res = http.get(url)
      #raise "Body was empty." if res.body.to_s.length <= 0
    end
  end
end