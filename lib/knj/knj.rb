if $knjpath
  autoload_path = "#{$knjpath}autoload.rb"
else
  $knjpath = "knj/"
  autoload_path = "#{File.dirname(__FILE__)}/autoload.rb"
end

require autoload_path if $knjautoload != false

module Knj
  def self.appserver_cli(filename)
    Knj::Os.chdir_file(filename)
    require "#{$knjpath}/includes/appserver_cli.rb"
  end
  
  def self.dirname(filepath)
    raise "Filepath does not exist: #{filepath}" if !File.exists?(filepath)
    return Knj::Php.realpath(File.dirname(filepath))
  end
  
  #Returns the path of the knjrbfw-framework.
  def self.knjrbfw_path
    return File.realpath(File.dirname(__FILE__))
  end
end