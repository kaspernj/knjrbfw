begin
	require "RMagick"
rescue LoadError
	require "rubygems"
	require "RMagick"
end