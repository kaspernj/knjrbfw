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
end