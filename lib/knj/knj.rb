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
  
  #Shortcut to Php4r.print_r.
  def self.p(*args, &block)
    require "php4r" if !Kernel.const_defined?(:Php4r)
    return Php4r.print_r(*args, &block)
  end
  
  def self.handle_return(args)
    if args[:block]
      args[:enum].each(&args[:block])
      return nil
    else
      return Array_enumerator.new(args[:enum])
    end
  end
  
  #Loads a gem by a given name. First tries to load the gem from a custom parent directory to enable loading of development-gems.
  def self.gem_require(gem_const, gem_name)
    #Return false if the constant is already loaded.
    return false if ::Kernel.const_defined?(gem_const)
    
    #Try to load gem from custom development-path.
    found_custom = false
    
    paths = [
      "#{File.realpath("#{File.dirname(__FILE__)}/../../..")}/#{gem_name}/lib/#{gem_name}.rb"
    ]
    paths.each do |path|
      if File.exists?(path)
        require path
        found_custom = true
        break
      end
    end
    
    #Custom-path could not be loaded - load gem normally.
    if !found_custom
      require gem_name
    end
    
    #Return true to enable detection of that something was loaded.
    return true
  end
end