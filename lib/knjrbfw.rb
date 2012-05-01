module Knj
end

$knjpath = "knj/" if !$knjpath
$: << File.dirname(__FILE__)

require "#{$knjpath}knj"