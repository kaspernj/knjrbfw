require "#{File.dirname(__FILE__)}/autoload.rb"

module Knj
	def self.appserver_cli(filename)
		Knj::Os.chdir_file(filename)
		require "#{File.dirname(__FILE__)}/includes/appserver_cli.rb"
	end
	
	def self.dirname(filepath)
		raise "Filepath does not exist: #{filepath}" if !File.exists?(filepath)
		return Knj::Php.realpath(File.dirname(filepath))
	end
end