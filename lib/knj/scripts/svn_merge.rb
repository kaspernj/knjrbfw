#!/usr/bin/ruby

require "knj/autoload"

path_to = ARGV[0]

Dir.glob(File.join("**", ".svn")).each do |dir|
	newdir = path_to + "/" + dir
	
	#print dir + "\n"
	#print newdir + "\n"
	
	if File.exists?(newdir)
		print "Remove: " + newdir.to_s + "\n"
		FileUtils.rm_r(newdir)
	end
	
	begin
		#print "Move: " + dir + "\n"
		#FileUtils.mv(dir, newdir)
		
		print "Copy: " + dir + "\n"
		FileUtils.cp_r(dir, newdir)
	rescue => e
		print "Failed: " + e.message + "\n"
	end
	
	#print "\n"
end