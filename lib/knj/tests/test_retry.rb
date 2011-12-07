#!/usr/bin/env ruby

Dir.chdir(File.dirname(__FILE__))
require "../autoload"

count = 0
result = Knj::Retry.try(
  :exit => false,
  :interrupt => true,
  :errors => [Knj::Errors::NotFound, RuntimeError],
  :timeout => 1,
  :tries => 3,
  :return_error => true
) do
  count += 1
  print "Count: #{count.to_s}\n"
  
  if count <= 2
    exit
  end
  
  if count <= 3
    
    #raise "Test"
  end
end

#print "Error 1 was a #{result[0][:error].class.to_s} with the message: #{result[0][:error].message.to_s}\n"

Knj::Php.print_r(result)