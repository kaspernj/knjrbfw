begin
	require "erubis"
rescue LoadError
	require "rubygems"
	require "erubis"
end