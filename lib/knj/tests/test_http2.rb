#!/usr/bin/env ruby1.9.1

Dir.chdir(File.dirname(__FILE__))
require "../../knjrbfw.rb"

require "../autoload"

http = Knj::Http2.new(:host => "www.partyworm.dk", :port => 80, :ssl => false)
resp = http.get("/?show=frontpage")
resp = http.get("/?show=login")

#print "Wee!\n"
#exit

http = Knj::Http2.new(:host => "mexico.balance4u.com", :port => 443, :ssl => true)
resp = http.get("/")

Knj::Php.print_r(http.cookies)