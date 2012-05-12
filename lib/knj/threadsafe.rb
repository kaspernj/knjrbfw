require "monitor"

#This module contains various tools to handle thread-safety easily and pretty.
module Knj::Threadsafe
  #JRuby can corrupt an array in a threadded env. Use this method to only get a synchronized array when running JRuby and not having to write "if RUBY_ENGINE"-stuff.
  def self.std_array
    return Synced_array.new if RUBY_ENGINE == "jruby"
    return []
  end
  
  #Instances of this class proxies calls to a given-object by using a mutex or monitor.
  #
  #==== Examples
  # threadsafe_array = Knj::Threadsafe::Proxy.new(:obj => [])
  # threadsafe_array << 5
  # ret = threadsafe_array[0]
  #
  # threadsafe_array = Knj::Threadsafe::Proxy.new(:obj => [], :monitor => true)
  class Proxy
    #Spawn needed vars.
    def initialize(args)
      if args[:monitor]
        @mutex = Monitor.new
      elsif args[:mutex]
        @mutex = args[:mutex]
      else
        @mutex = Mutex.new
      end
      
      @obj = args[:obj]
    end
    
    #Proxies all calls to this object through the mutex.
    def method_missing(method_name, *args, &block)
      @mutex.synchronize do
        @obj.__send__(method_name, *args, &block)
      end
    end
  end
  
  #This module can be included on a class to make all method-calls synchronized (by using monitor). Examples with array and hash are below.
  #
  #===Examples
  # class MySyncedClass < SomeOtherClassThatNeedsToBeSynchronized
  #   include Knj::Threadsafe::Monitored
  # end
  module Monitored
    def self.included(base)
      Knj::Strings.const_get_full(base.to_s).class_eval do
        self.instance_methods.each do |method_name|
          #These two methods create warnings under JRuby.
          if RUBY_ENGINE == "jruby"
            next if method_name == :instance_exec or method_name == :instance_eval
          end
          
          new_method_name = "_ts_#{method_name}"
          alias_method(new_method_name, method_name)
          
          define_method method_name do |*args, &block|
            #Need to use monitor, since the internal calls might have to run not-synchronized, and we have just overwritten the internal methods.
            @_ts_mutex = Monitor.new if !@_ts_mutex
            @_ts_mutex.synchronize do
              return self._ts___send__(new_method_name, *args, &block)
            end
          end
        end
      end
    end
  end
  
  #This module can be included on a class to make all method-calls synchronized (by using mutex). Examples with array and hash are below.
  #
  #===Examples
  # class MySyncedClass < SomeOtherClassThatNeedsToBeSynchronized
  #   include Knj::Threadsafe::Mutexed
  # end
  module Mutexed
    def self.included(base)
      Knj::Strings.const_get_full(base.to_s).class_eval do
        self.instance_methods.each do |method_name|
          #These two methods create warnings under JRuby.
          if RUBY_ENGINE == "jruby"
            next if method_name == :instance_exec or method_name == :instance_eval
          end
          
          new_method_name = "_ts_#{method_name}"
          alias_method(new_method_name, method_name)
          
          define_method method_name do |*args, &block|
            #Need to use monitor, since the internal calls might have to run not-synchronized, and we have just overwritten the internal methods.
            @_ts_mutex = Mutex.new if !@_ts_mutex
            @_ts_mutex.synchronize do
              return self._ts___send__(new_method_name, *args, &block)
            end
          end
        end
      end
    end
  end
  
  #Predefined synchronized array.
  #
  #===Examples
  # arr = Knj::Threadsafe::Synced_array.new
  # arr << 5
  # ret = arr[0]
  class Synced_array < ::Array
    include Monitored
  end
  
  #Predefined synchronized hash.
  #
  #===Examples
  # h = Knj::Threadsafe::Synced_hash.new
  # h['test'] = 'trala'
  # ret = h['test']
  class Synced_hash < ::Hash
    include Monitored
  end
end