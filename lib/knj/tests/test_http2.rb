#!/usr/bin/env ruby1.9.1

Dir.chdir(File.dirname(__FILE__))
require "../../knjrbfw.rb"

require "../autoload"

http = Http2.new(:host => "www.partyworm.dk", :port => 80, :ssl => false)
resp = http.get(:url => "/?show=frontpage")
resp = http.get(:url => "/?show=login")

#print "Wee!\n"
#exit

http = Http2.new(:host => "mexico.balance4u.com", :port => 443, :ssl => true)
resp = http.get(:url => "/")

Php4r.print_r(http.cookies)