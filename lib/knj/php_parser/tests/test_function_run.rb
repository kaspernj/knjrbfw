#!/usr/bin/env ruby

require "knj/autoload"
include Knj

parser = Php_parser.new(
  "file" => File.dirname(__FILE__) + "/test_function.php"
)

begin
  cont = parser.parse
rescue RuntimeError => e
  print "Retcont:\n#{parser.retcont}\n\n"
  print "Cont:\n#{parser.cont}\n\n"
  
  raise e
end

print cont + "\n"