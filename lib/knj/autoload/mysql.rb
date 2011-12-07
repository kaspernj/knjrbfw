begin
  require "mysql"
rescue LoadError
  require "rubygems"
  require "mysql"
end