begin
	require "parsedate"
rescue LoadError
	require File.dirname(__FILE__) + "/backups/parsedate.rb"
end