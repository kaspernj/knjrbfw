require "knj/autoload"
require "#{$knjpath}php"
require "#{$knjpath}php_parser/php_parser"

module Knj::Php_parser::Functions
  def self.my_function(phpvar_arg)
    Knj::Php.print("Hejsa.\n")
    Knj::Php.print(phpvar_arg + "\n")
  end
end
Knj::Php_parser::Functions.my_function("Helloworld.")

