#!/usr/bin/env ruby

Dir.chdir(File.dirname(__FILE__))
require "../autoload"

Knj::Retry.try

Knj::Retry.try(
	:exit => true,
	:errors => [Knj::Errors::NotFound],
	:timeout => 1,
	:tries => 1
) do
	sleep 2
end