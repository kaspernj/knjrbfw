#!/usr/bin/jruby

require "fcgi"
FCGI.each_cgi do |fcgi|
	print "Content-Type: text/html\n\n"
	print "Hello world."
end
