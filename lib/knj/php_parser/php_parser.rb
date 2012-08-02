class Knj::Php_parser
  attr_reader :cont, :retcont
  
  def initialize(args)
    @args = args
    @cont = File.read(@args["file"])
    
    if !args.key?("require_requirements") or args["require_requirements"]
      @retcont = "require \"knj/autoload\"\n"
      @retcont << "require \"php4r\"\n"
      @retcont << "require \"knj/php_parser/php_parser\"\n"
      @retcont << "\n"
    else
      @retcont = ""
    end
  end
end

require File.dirname(__FILE__) + "/functions.rb"

module Knj::Php_parser::Functions
  #nothing here.
end