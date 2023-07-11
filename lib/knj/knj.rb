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
    raise "Filepath does not exist: #{filepath}" if !File.exist?(filepath)
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
  def self.gem_require(gem_const, gem_name = nil)
    #Support given an array for multiple gem-names in one call.
    if gem_const.is_a?(Array) and gem_name == nil
      gem_const.each do |gem_i|
        self.gem_require(gem_i)
      end

      return nil
    end

    #Set correct names.
    gem_name = gem_const.to_s.downcase.strip if !gem_name
    gem_const = "#{gem_const.to_s[0].upcase}#{gem_const.to_s[1, gem_name.length]}"

    #Return false if the constant is already loaded.
    return false if ::Kernel.const_defined?(gem_const)

    #Try to load gem from custom development-path.
    found_custom = false

    paths = [
      "#{File.realpath("#{File.dirname(__FILE__)}/../../..")}/#{gem_name}/lib/#{gem_name}.rb"
    ]
    paths.each do |path|
      if File.exist?(path)
        require path
        found_custom = true
        break
      end
    end

    #Custom-path could not be loaded - load gem normally.
    if !found_custom
      require "rubygems"
      require gem_name.to_s
    end

    #Return true to enable detection of that something was loaded.
    return true
  end
end