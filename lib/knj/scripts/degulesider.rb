#!/usr/bin/env ruby

require "knj/autoload"
include Knj

dgs = Degulesider.new
res = dgs.search(
  :where => ARGV[0],
  :what => ARGV[1]
)

print JSON.generate(res)