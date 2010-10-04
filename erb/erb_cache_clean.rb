#!/usr/bin/env ruby

require "knj/autoload"
include Knj
Os.chdir_file(__FILE__)

curtime = Time.new.to_i

Dir.new("cache").each do |filename|
	if filename != "." and filename != ".." and filename != "README"
		fn = "cache/#{filename}"
		file = File.new(fn)
		mtime = file.mtime.to_i
		diftime = curtime - mtime
		
		if diftime >= (3600 * 48)
			File.delete(fn)
		end
	end
end