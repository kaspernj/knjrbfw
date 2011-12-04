begin
  require "zip/zip"
rescue LoadError
  require "rubygems"
  require "zip"
end