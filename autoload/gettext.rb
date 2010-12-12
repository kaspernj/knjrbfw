begin
	require "gettext"
rescue LoadError
	require "rubygems"
	require "gettext"
end