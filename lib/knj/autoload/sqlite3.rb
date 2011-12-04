begin
  require "sqlite3"
rescue LoadError
  require "rubygems"
  require "sqlite3"
end