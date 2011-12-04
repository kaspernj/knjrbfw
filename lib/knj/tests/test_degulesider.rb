#!/usr/bin/env ruby

require "knj/autoload"
include Knj

dgs = Degulesider.new
results = dgs.search(
  :where => "Engvej 3, 4970 Rødby"
)

Php.print_r(results)