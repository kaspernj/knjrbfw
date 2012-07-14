#!/usr/bin/env ruby

require "timeout"

args = {}
ARGV.each do |arg|
  if match = arg.match(/^tmpfile=(.+)$/)
    args["tmpfile"] = match[1]
  else
    raise "Unknown argument: '#{arg}'."
  end
end

raise "No 'tmpfile' given in arguments." if !args["tmpfile"]

#8 kb string.
str = ("0" * 1024) * 8
strl = str.length

count = 0
time_begin = Time.now.to_f

puts "Starting to write file."
begin
  Timeout.timeout(4) do
    File.open(args["tmpfile"], "w") do |fp|
      fp.sync = true
      
      loop do
        fp.write(str)
        count += strl
      end
    end
  end
rescue Timeout::Error
  #ignore
end

secs = Time.now.to_f - time_begin
mb_sec = ((count / secs) / 1024) / 1024

puts "#{mb_sec.round(2)} mb/s in #{secs.round(1)} seconds."


puts "Starting to read the file again."
count = 0
time_begin = Time.now.to_f

begin
  Timeout.timeout(4) do
    File.open(args["tmpfile"], "r") do |fp|
      loop do
        read = fp.read(4096)
        count += read.length
      end
    end
  end
rescue Timeout::Error
  #ignore
end

secs = Time.now.to_f - time_begin
mb_sec = ((count / secs) / 1024) / 1024

puts "#{mb_sec.round(2)} mb/s in #{secs.round(1)} seconds."

File.unlink(args["tmpfile"])