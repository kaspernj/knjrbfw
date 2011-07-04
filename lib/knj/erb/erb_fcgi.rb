#!/usr/bin/env ruby

def File::realpath(path)
	if File.symlink?(path)
		return self.realpath(File.readlink(path))
	end
	
	return path
end

require File.dirname(File.realpath(__FILE__)) + "/../autoload"

$_FCGI_COUNT = 0
require File.dirname(File.realpath(__FILE__)) + "/include"
$knj_eruby = KnjEruby
FCGI.each_cgi do |fcgi|
	$_FCGI_COUNT += 1
	$_CGI = fcgi
	$_FCGI = fcgi
	
	loadfp = File.dirname(__FILE__) + "/" + File.basename(__FILE__).slice(0..-6) + ".rhtml"
	
	begin
		KnjEruby.fcgi = fcgi
		KnjEruby.load(loadfp)
		
		if KnjEruby.connects["exit"]
			KnjEruby.connects["exit"].each do |block|
				block.call
			end
		end
		
		if $_FCGI_EXIT
			#Kill self! Need to start a new thread because the app as to finish. Give it 0.1 second to do that before killing it.
			Thread.new do
				sleep 0.5
				Process.kill(9, Process.pid)
			end
		end
	rescue Exception => e
		puts e.inspect
		puts e.backtrace
	end
end