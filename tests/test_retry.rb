#!/usr/bin/env ruby

Dir.chdir(File.dirname(__FILE__))
require "../autoload"

count = 0
Knj::Retry.try(
	:exit => true,
	:errors => [Knj::Errors::NotFound, RuntimeError],
	:timeout => 1,
	:tries => 2,
	:wait => 2
) do
	count += 1
	
	print "Test: #{count.to_s}\n"
	raise "Test"
end