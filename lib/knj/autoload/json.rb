require "rubygems"

begin
  if RUBY_ENGINE == "jruby"
    require "json/pure" #normal json has utf-8 encoding problems - knj.
  else
    require "json/pure"
    
    #deactivated because of problems with utf-8 encoding.
    #require "json/ext"
  end
rescue LoadError
  require "json/pure"
end