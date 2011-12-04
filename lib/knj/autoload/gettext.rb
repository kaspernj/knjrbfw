#In some version just requiring gettext givet an error because you have to define the constant first... weird...
module GetText; end

begin
  require "gettext"
rescue LoadError
  require "rubygems"
  require "gettext"
end