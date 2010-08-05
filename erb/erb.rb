#!/usr/bin/env ruby

def File::realpath(path)
	if File.symlink?(path)
		return self.realpath(File.readlink(path))
	end
	
	return path
end

knjdir = File.dirname(File.realpath(__FILE__)) + "/../"

require knjdir + "autoload"
require knjdir + "web"
require "erubis"

class KnjEruby < Erubis::Eruby
	include Erubis::StdoutEnhancer
	@headers = [
		["Content-Type", "text/html; charset=utf-8"]
	]
	@filepath = File.dirname(Knj::Os::realpath(__FILE__))
	
	def self.print_headers
		header_str = ""
		@headers.each do |header|
			header_str += "#{header[0]}: #{header[1]}\n"
		end
		
		header_str += "\n"
		print header_str
	end
	
	def self.header(key, value)
		@headers << [key, value]
	end
	
	def self.filepath
		return @filepath
	end
end

$knj_eruby = KnjEruby

class ERuby
	def self.import(filename)
		filename = File.expand_path(filename)
		
		pwd = Dir.pwd
		Dir.chdir(File.dirname(filename))
		cachename = "#{KnjEruby.filepath}/cache/#{filename.gsub("/", "_").gsub(".", "_")}.cache"
		eruby = KnjEruby.load_file(File.basename(filename), {:cachename => cachename})
		print eruby.evaluate
		Dir.chdir(pwd)
	end
end

begin
	filename = ENV["PATH_TRANSLATED"] if ENV and ENV["PATH_TRANSLATED"]
	filename = ARGV[0] if ARGV and ARGV[0]
	
	tmp_out = StringIO.new
	$stdout = tmp_out
	ERuby.import(filename)
	
	$stdout = STDOUT
	KnjEruby.print_headers
	tmp_out.rewind
	print tmp_out.read
rescue SystemExit => e
	$stdout = STDOUT
	KnjEruby.print_headers
	
	tmp_out.rewind
	print tmp_out.read
	
	exit
rescue Exception => e
	$stdout = STDOUT
	KnjEruby.print_headers
	
	if tmp_out
		tmp_out.rewind
		print tmp_out.read
	end
	
	print "\n\n<pre>\n\n"
	print "<b>#{e.class.name.html}: #{e.message.html}</b>\n\n"
	
	#Lets hide all the stuff in what is not the users files to make it easier to debug.
	bt = e.backtrace
	to = bt.length - 9
	bt = bt[0..to]
	
	bt.reverse.each do |line|
		print line.html + "\n"
	end
end