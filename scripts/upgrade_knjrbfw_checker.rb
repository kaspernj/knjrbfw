#!/usr/bin/env ruby

require "knj/autoload"

mode = ARGV[0]

if mode.to_s.length <= 0
	print "No mode was given.\n"
	exit
elsif mode != "dev" and mode != "original"
	print "Invalid mode: #{mode}\n"
	exit
end

checks = [
	"/usr/share/php/knjphpframework",
	"/usr/lib/ruby/1.8/knjrbfw"
]

checks.each do |dir|
	dev_name = dir + "_dev"
	original_name = dir + "_original"
	
	if mode == "dev"
		if File.symlink?(dir)
			#do nothing.
		else
			File.rename(dir, original_name)
			File.rename(dev_name, dir)
		end
	elsif mode == "original"
		if File.symlink?(dir)
			File.rename(dir, dev_name)
			File.rename(original_name, dir)
		else
			#do nothing.
		end
	else
		raise "No such mode: #{mode}"
	end
end