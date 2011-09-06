#!/usr/bin/env ruby

require "knj/autoload"
include Knj

begin
	options = {}
	OptionParser.new do |opts|
		opts.banner = "Usage: example.rb [options]"
		
		opts.on("-f FINDTHIS", "--find", "Search for this string.") do |f|
			options[:find] = f
		end
		
		opts.on("-b BYTES", "--bytes BYTES", "Return this number of bytes and finding the string.") do |b|
			options[:bytes] = b.to_i
		end
		
		opts.on("--filepath FILEPATH", "The file that should be searched.") do |fp|
			options[:filepath] = fp
		end
	end.parse!
rescue OptionParser::InvalidOption => e
	Php.die(e.message + "\n")
end

cont = ""
readstr = ""
retcont = ""
File.open(options[:filepath], "r") do |fp|
	loop do
		break if fp.eof
		
		prevcont = String.new(readstr)
		readstr = fp.read(1024)
		cont = prevcont + readstr
		
		if ind = cont.index(options[:find])
			read_size = options[:bytes] - (cont.length - ind)
			
			if read_size > 0
				cont += fp.read(read_size)
			end
			
			retcont = cont.slice(ind, options[:bytes])
			break
		end
	end
end

print retcont + "\n"