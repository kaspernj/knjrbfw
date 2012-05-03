#!/usr/bin/env ruby

require "knj/autoload"

dgs = Knj::Degulesider.new
results = dgs.search(
  :where => "Engvej 3, 4970 Rødby"
)

Knj::Php.print_r(results)