#Copied from Headius: https://github.com/headius/thread_safe. Not just bundeled because I would like to make changes later...
#Minor modifications from Headius's original lib like submoduled, lower-case-safe and more...

if defined?(JRUBY_VERSION)
  require "jruby/synchronized"
  
  module Knj::Threadsafe
    # A thread-safe subclass of Array. This version locks
    # against the object itself for every method call,
    # ensuring only one thread can be reading or writing
    # at a time. This includes iteration methods like
    # #each.
    class Array < ::Array
      include JRuby::Synchronized
    end
    
    # A thread-safe subclass of Hash. This version locks
    # against the object itself for every method call,
    # ensuring only one thread can be reading or writing
    # at a time. This includes iteration methods like
    # #each.
    class Hash < ::Hash
      include JRuby::Synchronized
    end
  end
else
  # Because MRI never runs code in parallel, the existing
  # non-thread-safe structures should usually work fine.
  module Knj::ThreadSafe
    Array = ::Array
    Hash = ::Hash
  end
end