begin
  require "tmail"
rescue LoadError
  require "rubygems"
  require "tmail"
end