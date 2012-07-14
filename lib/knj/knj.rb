$knjpath = "knj/" if !$knjpath

module Knj
  CONFIG = {}
  
  def self.const_missing(name)
    if name == :Db
      filepath = "#{$knjpath}knjdb/libknjdb"
    else
      filepath = "#{$knjpath}#{name.to_s.downcase}"
    end
    
    require filepath
    raise "Constant still not defined: '#{name}'." if !Knj.const_defined?(name)
    return Knj.const_get(name)
  end
  
  def self.appserver_cli(filename)
    Knj::Os.chdir_file(filename)
    require "#{$knjpath}/includes/appserver_cli.rb"
  end
  
  def self.dirname(filepath)
    raise "Filepath does not exist: #{filepath}" if !File.exists?(filepath)
    return File.realpath(File.dirname(filepath))
  end
  
  #Returns the path of the knjrbfw-framework.
  def self.knjrbfw_path
    return File.realpath(File.dirname(__FILE__))
  end
  
  #Shortcut to Knj::Php.print_r.
  def self.p(*args, &block)
    return Knj::Php.print_r(*args, &block)
  end
  
  def self.handle_return(args)
    if args[:block]
      args[:enum].each(&args[:block])
      return nil
    else
      return Array_enumerator.new(args[:enum])
    end
  end
end