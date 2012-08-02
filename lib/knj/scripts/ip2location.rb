#!/usr/bin/env ruby

require "knj/autoload"
ip2loc = Knj::Ip2location.new

data = ip2loc.lookup(ARGV[0])

if ARGV[1] == "json"
  print Php4r.json_encode(data)
else
  Php4r.print_r(data)
end