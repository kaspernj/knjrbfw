#!/usr/bin/env ruby

require "knj/autoload"
require "knj/web"
require "erubis"

class KnjEruby < Erubis::Eruby
	include Erubis::StdoutEnhancer
	@headers = [
		["Content-Type", "text/html; charset=utf-8"]
	]
	
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
end

$knj_eruby = KnjEruby

class ERuby
	def self.import(filename)
		pwd = Dir.pwd
		Dir.chdir(File.dirname(filename))
		cachename = File.dirname(Knj::Os::realpath(__FILE__)) + "/cache/#{filename.gsub("/", "_")}.cache"
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
	print "#{e.class.name.html}: #{e.message.html}\n\n"
	
	e.backtrace.each do |line|
		print line.html + "\n"
	end
end