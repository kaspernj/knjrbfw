#!/usr/bin/env ruby1.9

knjdir = File.dirname(File.realpath(__FILE__)) + "/../"

require knjdir + "autoload"
require knjdir + "/erb/include"

$knj_eruby = KnjEruby

filename = ENV["PATH_TRANSLATED"] if ENV and ENV["PATH_TRANSLATED"]
filename = ARGV[0] if ARGV and ARGV[0]

KnjEruby.load(filename)