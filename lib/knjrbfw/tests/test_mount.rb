#!/usr/bin/env ruby

Dir.chdir(File.dirname(__FILE__))
require "../autoload"

print "Listing all mounts.\n"
mounts = Knj::Mount.list
mounts.each do |mount|
	Knj::Php.print_r(mount.data)
	print "Access: #{mount.access?}\n\n"
end

mounts = Knj::Mount.list("from_search" => "test_dir")
mounts.each do |mount|
	print "Unmounting test_dir.\n"
	mount.umount
end

print "Mount binding test_dir to test_dir_to.\n"
Knj::Mount.mount(
	"from" => "test_dir",
	"to" => "test_dir_to",
	"bind" => true
)

mounts = Knj::Mount.list("from_search" => "test_dir")
mounts.each do |mount|
	print "Unmounting test_dir.\n"
	mount.umount
end