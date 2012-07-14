#!/usr/bin/env ruby1.9.1

require "#{File.dirname(__FILE__)}/../../knjrbfw.rb"
require "knj/autoload"

proxy_settings = Marshal.load(File.read("#{File.dirname(__FILE__)}/test_http2_proxy_settings.marshal"))

http = Http2.new(
  :host => "www.partyworm.dk",
  :proxy => proxy_settings
)

urls = [
  "?show=users_search",
  "?show=users_online",
  "?show=drinksdb",
  "?show=forum&fid=9&tid=1917&page=0"
]
urls = ["robots.txt"]

0.upto(105) do |count|
  url = urls[rand(urls.size)]
  print "Doing request #{count} of 200 (#{url}).\n"
  res = http.get(:url => url)
  raise "Body was empty." if res.body.to_s.length <= 0
end