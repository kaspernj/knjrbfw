begin
  require "rmagick"
rescue LoadError
  require "rubygems"
  require "rmagick"
end