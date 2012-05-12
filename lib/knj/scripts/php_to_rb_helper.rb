#!/usr/bin/env ruby1.9.1

require "#{File.dirname(__FILE__)}/../../knjrbfw.rb"
require "knj/autoload"

begin
  options = {}
  OptionParser.new do |opts|
    opts.banner = "Usage: example.rb [options]"
    
    opts.on("-f PHPFILE", "--file", "The PHP-file you want help to convert.") do |f|
      options[:file] = f
    end
    
    opts.on("-t", "--tags-remove", "Removes the PHP-tags completely.") do |t|
      options[:tags] = false
    end
  end.parse!
rescue OptionParser::InvalidOption => e
  print "#{e.message}\n"
  exit
end

raise "No PHP-file given with -f." if !options[:file]

cont = File.read(options[:file])
regexes = {
  "var" => "[A-z0-9_]+",
  "class" => "[A-z0-9_]+"
}


#Replace shell PHP.
cont.gsub!(/\A#!\/usr\/bin\/env\s+php5/, "!#/usr/bin/env ruby1.9.1")


#Replace class extends.
cont.scan(/(class\s+(.+?)\s+extends\s+(.+?){)/) do |match|
  rb_classname = "#{match[1][0..0].upcase}#{match[1][1..999]}"
  
  if match[2] == "knjdb_row"
    extends = "Knj::Datarow"
  else
    extends = "#{match[2][0..0].upcase}#{match[2][1..999]}"
  end
  
  rb_str = "class #{rb_classname} < #{extends}"
  
  cont = cont.gsub(match[0], rb_str)
end


#Replace non-extended classes.
cont.scan(/(class\s+(.+?)\s*{)/) do |match|
  rb_classname = "#{match[1][0..0].upcase}#{match[1][1..999]}"
  rb_str = "class #{rb_classname}"
  
  cont = cont.gsub(match[0], rb_str)
end


#Match and replace static methods.
cont.scan(/(static\s+function\s+(.+?)\((.*?)\)\s*{)/) do |match|
  if match[1] == "getList"
    func_name = "list"
  elsif match[1] == "addNew"
    func_name = "add"
  else
    func_name = match[1]
  end
  
  rb_str = "def self.#{func_name}(#{match[2]})"
  cont = cont.gsub(match[0], rb_str)
end


#Match and replace public variables on classes.
public_vars = {}
cont.scan(/(public\s+\$(#{regexes["var"]})\s+=\s+(.+?)\s*;\n)/) do |match|
  public_vars[match[1]] = match[1]
  rb_str = "attr_accessor :#{match[1]}\n"
  cont = cont.gsub(match[0], rb_str)
end

cont.scan(/(public\s\$(#{regexes["var"]})\s*;)/) do |match|
  public_vars[match[1]] = match[1]
  rb_str = "attr_accessor :#{match[1]}"
  cont = cont.gsub(match[0], rb_str)
end



#Match try exception handeling.
cont.scan(/((\s+?)try\s*{(\s+?))/) do |match|
  rb_str = "#{match[1]}begin#{match[2]}"
  cont = cont.gsub(match[0], rb_str)
end


#Match catch exception handeling.
cont.scan(/((\s+?)}\s*catch\s*\(\s*(#{regexes["class"]})\s+\$(#{regexes["var"]})\s*\)\s*{(\s+))/) do |match|
  classname = "#{match[2][0..0].upcase}#{match[2][1..999]}"
  classname = "Knj::Errors::NotFound" if classname == "Knjdb_rownotfound_exception"
  
  rb_str = "#{match[1]}rescue #{classname} => #{match[3]}#{match[4]}"
  cont = cont.gsub(match[0], rb_str)
end


#Match requires
cont.scan(/((\s+?)require_once\s+\"(.+)\"\s*;(\s+?))/) do |match|
  filename = match[2]
  filename.gsub!(/\.php$/, ".rb")
  
  rb_str = "#{match[1]}require \"#{filename}\"#{match[3]}"
  cont = cont.gsub(match[0], rb_str)
end


cont.scan(/(function\s(.+?)\((.*?)\))/) do |match|
  #Try to solve problems when arguments are type-required.
  def_args = match[2]
  def_args.scan(/(([A-z]+)\s+\$(#{regexes["var"]}))/) do |match_arg|
    def_args = def_args.gsub(match_arg[0], "#{match_arg[2]}")
  end
  
  rb_str = "def #{match[1]}(#{def_args})"
  cont = cont.gsub(match[0], rb_str)
end

cont.scan(/((\s+?)}\s*else\s*{(\s+?))/) do |match|
  rb_str = "#{match[1]}else#{match[2]}"
  cont = cont.gsub(match[0], rb_str)
end

cont.scan(/((\s+?)}\s*else\s*if\s*\()/) do |match|
  rb_str = "#{match[1]}elsif("
  cont = cont.gsub(match[0], rb_str)
end

cont.scan(/((\s+|^)}\n)/) do |match|
  rb_str = "#{match[1]}end\n"
  cont = cont.gsub(match[0], rb_str)
end

cont.gsub!(/\n}\Z/, "\nend")


#Replace nulls.
cont.gsub!(/([^A-z0-9_])null([^A-z0-9_])/, "\\1nil\\2")


#Replace exception throws.
cont.scan(/(throw\s+new\s+exception\s*\()/i) do |match|
  rb_str = "raise("
  cont = cont.gsub(match[0], rb_str)
end


#Replace various forms of foreach'es.
cont.scan(/((\s+?)foreach\s*\((.+?)\s+as\s+\$(#{regexes["var"]}?)\s+=>\s+\$(#{regexes["var"]}?)\)\s*{(\s+?))/i) do |match|
  rb_str = "#{match[1]}Knj::Php.foreach(#{match[2]}) do |$#{match[3]}, $#{match[4]}|#{match[5]}"
  cont = cont.gsub(match[0], rb_str)
end

cont.scan(/((\s+?)foreach\s*\((.+?)\s+as\s+\$(#{regexes["var"]}?)\s*\)\s*{(\s+?))/i) do |match|
  rb_str = "#{match[1]}Knj::Php.foreach(#{match[2]}) do |$#{match[3]}|#{match[4]}"
  cont = cont.gsub(match[0], rb_str)
end


#Replace math stuff.
cont.scan(/((\s+)\$(#{regexes["var"]}?)\+\+;(\s+?))/) do |match|
  rb_str = "#{match[1]}#{match[2]} += 1#{match[3]}"
  cont = cont.gsub(match[0], rb_str)
end


#Replace double equal.
cont.gsub!(/(\s+)!==(\s+)/, "\\1!=\\2")


#Replace string additions.
cont.scan(/((\s+)\$(#{regexes["var"]}?)\s+\.=(\s+))/) do |match|
  rb_str = "#{match[1]}$#{match[2]} = $#{match[2]}.to_s +#{match[3]}"
  cont = cont.gsub(match[0], rb_str)
end

cont.scan(/("\s*\.\s*\$(#{regexes["var"]})(\s+)\.\s*")/) do |match|
  rb_str = "\" + $#{match[1]}.to_s + \""
  cont = cont.gsub(match[0], rb_str)
end

cont.scan(/("\s*\.\s*\$(#{regexes["var"]})\s+\.(\s+))/) do |match|
  rb_str = "\" + $#{match[1]}.to_s +#{match[2]}"
  cont = cont.gsub(match[0], rb_str)
end

cont.scan(/("\s*\.\s*\$(#{regexes["var"]}?)(\s+|,|;|\$|\)))/) do |match|
  rb_str = "\" + $#{match[1]}.to_s#{match[2]}"
  cont = cont.gsub(match[0], rb_str)
end

cont.scan(/("\s*\.\s+(#{regexes["var"]})\()/) do |match|
  rb_str = "\" + #{match[1]}("
  cont = cont.gsub(match[0], rb_str)
end

cont.scan(/(\)\s+.\s+")/) do |match|
  rb_str = ") + \""
  cont = cont.gsub(match[0], rb_str)
end

cont.scan(/(\"\s*\.\s*(knj_browser))/) do |match|
  rb_str = "\" + #{match[1]}"
  cont = cont.gsub(match[0], rb_str)
end

cont.scan(/(\$(#{regexes["var"]})\s*\.\s*\")/) do |match|
  rb_str = "$#{match[1]}.to_s + \""
  cont = cont.gsub(match[0], rb_str)
end


#Replace cases.
cont.scan(/((\s+)case\s+(.+?)\s*:(\s{0,1}))/) do |match|
  rb_str = "#{match[1]}when #{match[2]}#{match[3]}"
  cont = cont.gsub(match[0], rb_str)
end


#Replace switches.
cont.scan(/((\s+)switch\s*\(\s*\$(.+?)\s*\)\s*{(\s+))/) do |match|
  rb_str = "#{match[1]}case $#{match[2]}#{match[3]}"
  cont = cont.gsub(match[0], rb_str)
end


#Replace defaults.
cont.scan(/((\s+)default\s*:(\s+))/) do |match|
  rb_str = "#{match[1]}else#{match[2]}"
  cont = cont.gsub(match[0], rb_str)
end


#Replace continues
cont.scan(/((\s+?)continue\s*;(\s+?))/) do |match|
  rb_str = "#{match[1]}next#{match[2]}"
  cont = cont.gsub(match[0], rb_str)
end


#Replace one-line comments.
cont.scan(/(\/\/(.+?)\n)/) do |match|
  rb_str = "##{match[1]}\n"
  cont = cont.gsub(match[0], rb_str)
end


#Replace one-line comments formed as multi-lined ones.
cont.scan(/((\s+)\/\*(\*|)\s*([^\n]+?)\s*\*\/\n)/) do |match|
  rb_str = "#{match[1]}##{match[3]}\n"
  cont = cont.gsub(match[0], rb_str)
end


#Replace multi-line comments.
cont.scan(/((\s+|<\?)\/\*([\s\S]+?)\*\/)/) do |match|
  rb_str = "\n=begin\n#{match[2]}\n=end\n"
  
  if match[1] == "<?"
    rb_str = "<%#{rb_str}"
  end
  
  cont = cont.gsub(match[0], rb_str)
end


#Replace variable by reference.
cont.scan(/((\s+)\$(#{regexes["var"]}?)\s+=\s+&)/) do |match|
  rb_str = "#{match[1]}#{match[2]} = "
  cont = cont.gsub(match[0], rb_str)
end


#Check for global variables definitions.
global_vars = {
  "_GET" => "_get",
  "_POST" => "_post",
  "_SERVER" => "_meta",
  "_COOKIE" => "_cookie"
}
cont.scan(/((\s+)global\s+\$(#{regexes["var"]})\s*;)/) do |match|
  global_vars[match[2]] = "$#{match[2]}"
  rb_str = "#{match[1]}#global $#{match[2]}"
  cont = cont.gsub(match[0], rb_str)
end


#Replace variable-names.
cont.scan(/(([^%\d])(\$(#{regexes["var"]})))/) do |match|
  vname = match[3]
  
  if vname[-1..-1] == "["
    vname = vname[0..-2]
    match[0] = match[0][0..-2]
    match[2] = match[2][0..-2]
    match[3] = match[3][0..-2]
  end
  
  if vname == "this"
    rb_varname = "self"
  elsif global_vars.key?(vname)
    rb_varname = global_vars[vname]
  else
    rb_varname = "#{vname}"
  end
  
  cont = cont.gsub(match[2], rb_varname)
end

replaces = {
  "{\n" => "\n",
  "ob()" => "_ob",
  "db()" => "_db",
  "->" => ".",
  ";\n" => "\n"
}

pinfo = Knj::Php.pathinfo(options[:file])

if options.key?(:tags) and !options[:tags]
  rbfname = "#{pinfo["basename"]}.rb"
  replaces.merge!(
    /<\?php(\s*)/ => "",
    /<\?(\s*)/ => "",
    /\?>(\s*)/ => ""
  )
else
  rbfname = "#{pinfo["basename"]}.rhtml"
  replaces.merge!(
    /<\?\s*}\s*else\s*{\s*\?>/ => "<%else%>",
    "<?}?>" => "<%end%>",
    "{?>" => "%>",
    "<?php" => "<%",
    "<?" => "<%",
    "?>" => "%>"
  )
end

replaces.each do |key, val|
  cont = cont.gsub(key, val)
end

funcs_skip = [:foreach]
funcs_remove = [:session_start]
funcs_all = funcs_skip | Knj::Php.instance_methods

funcs_all.each do |method_name|
  next if funcs_skip.index(method_name) != nil
  cont.scan(/((\s+|\(|!)#{method_name}\s*\()/) do |match|
    if funcs_remove.index(method_name) != nil
      cont = cont.gsub(match[0], "#{match[1]}#removal of func: #{method_name}(")
    else
      cont = cont.gsub(match[0], "#{match[1]}Knj::Php.#{method_name}(")
    end
  end
end

if pinfo["dirname"].to_s.length > 0
  rbfname = "#{pinfo["dirname"]}/#{rbfname}"
end

Knj::Php.file_put_contents(rbfname, cont)
#require "#{Dir.pwd}/#{rbfname}"
#print cont