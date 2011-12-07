require "knj/knj"
require "#{$knjpath}compiler"

compiler = Knj::Compiler.new

time_start = Time.new.to_f

#0.upto(10000) do
  compiler.eval_file("compiler_test_file.rb")
#end

time_spent = Time.new.to_f - time_start
print "#{time_spent}\n"