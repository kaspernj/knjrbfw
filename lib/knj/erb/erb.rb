#!/usr/bin/env ruby

def File::realpath(path)
	if File.symlink?(path)
		return self.realpath(File.readlink(path))
	end
	
	return path
end

knjdir = File.dirname(File.realpath(__FILE__)) + "/../"

require knjdir + "autoload"
require knjdir + "erb/include"

$knj_eruby = KnjEruby

filename = ENV["PATH_TRANSLATED"] if ENV and ENV["PATH_TRANSLATED"]
filename = ARGV[0] if ARGV and ARGV[0]

KnjEruby.load(filename)