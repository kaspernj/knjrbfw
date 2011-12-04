require "rubygems"

begin
  require "facets/dictionary"
rescue LoadError
  require File.dirname(__FILE__) + "/backups/facets_dictionary"
end