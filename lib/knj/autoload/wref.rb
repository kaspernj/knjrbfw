begin
  require "wref" if !Kernel.const_defined?(:Wref)
rescue LoadError
  require "rubygems"
  require "wref" if !Kernel.const_defined?(:Wref)
end