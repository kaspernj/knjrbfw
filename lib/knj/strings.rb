#encoding: utf-8

Knj.gem_require "php4r" if !Kernel.const_defined?(:Php4r)

#This module contains various methods to escape, change or treat strings.
module Knj::Strings
  #Returns a string that is safe to use on the command line.
  def self.UnixSafe(tha_string)
    return tha_string.to_s.gsub(" ", "\\ ").gsub("&", "\&").gsub("(", "\\(").gsub(")", "\\)").gsub('"', '\"').gsub("\n", "\"\n\"").gsub(":", "\\:").gsub('\'', "\\\\'").gsub("`", "\\\\`")
  end
  
  #Alias for UnixSafe.
  def self.unixsafe(string)
    return Knj::Strings.UnixSafe(string)
  end
  
  #Returns true if given string is regex-compatible.
  def self.is_regex?(str)
    if str.to_s.match(/^\/(.+)\/(i|m|x|)$/)
      return true
    else
      return false
    end
  end
  
  #Returns a Regexp-object from the string formatted as what you would give to Php's preg_match.
  def self.regex(str)
    first_char = str[0, 1]
    raise "First char should be '/' but wasnt: '#{first_char}'." if first_char != "/"
    first_pos = 1
    
    second_pos = str.rindex("/")
    pattern = str[first_pos, second_pos - 1]
    
    flags = str[second_pos + 1, str.length].to_s
    arg_two = 0
    
    if flags
      flags.length.times do |i|
        arg = flags[i, 1]
        
        case arg
          when "i"
            arg_two |= Regexp::IGNORECASE
          when "m"
            arg_two |= Regexp::MULTILINE
          when "x"
            arg_two |= Regexp::EXTENDED
          when "U"
            raise ArgumentError, "Ruby does (as far as I know) not support the 'U'-modifier. You should rewrite your regex with non-greedy operators such as '(\d+?)' instead for: '#{str}'."
          else
            raise "Unknown argument: '#{arg}'."
        end
      end
    end
    
    return Regexp.new(pattern, arg_two)
  end
  
  #Partens a string up in blocks for whatever words can be used to search for. Supports a block or returns an array.
  def self.searchstring(string, &block)
    words = [] if !block
    string = string.to_s
    
    matches = string.scan /(\"(.+?)\")/
    matches.each do |matcharr|
      word = matcharr[1]
      
      if word and word.length > 0
        if block
          yield(matcharr[1])
        else
          words << matcharr[1]
        end
        
        string = string.gsub(matcharr[0], "")
      end
    end
    
    string.split(/\s/).each do |word|
      if word and word.length > 0
        if block
          yield(word)
        else
          words << word
        end
      end
    end
    
    return nil if block
    return words
  end
  
  #Returns boolean if the strings is a correctly formatted email: k@spernj.org.
  def self.is_email?(str)
    return true if str.to_s.match(/^\S+@\S+\.\S+$/)
    return false
  end
  
  #Returns boolean if the string is a correctly formatted phonenumber as: +4512345678.
  def self.is_phonenumber?(str)
    return true if str.to_s.match(/^\+\d{2}\d+$/)
    return false
  end
  
  def self.js_safe(str, args = {})
    str = "#{str}"
    
    if args[:quotes_to_single]
      str.gsub!('"', "'")
    end
    
    str = str.gsub("\r", "").gsub("\n", "\\n").gsub("'", "\\\\'")
    
    if !args.key?(:quotes) or args[:quotes]
      str.gsub!('"', '\"')
    end
    
    return str
  end
  
  #Returns 'Yes' or 'No' based on a value. The value can be 0, 1, yes, no, true or false.
  def self.yn_str(value, str_yes = "Yes", str_no = "No")
    value = value.to_i if (Float(value) rescue false)
    value_s = value.to_s
    
    if value.is_a?(Integer)
      if value == 0
        return str_no
      else
        return str_yes
      end
    end
    
    return str_no if !value or value_s == "no" or value_s == "false" or value_s == ""
    return str_yes
  end
  
  #Shortens a string to maxlength and adds "..." if it was shortened.
  #===Examples
  # Knj::Strings.shorten("Kasper Johansen", 6) #=> "Kasper..."
  def self.shorten(str, maxlength)
    str = str.to_s
    str = str.slice(0..(maxlength - 1)).strip + "..." if str.length > maxlength
    return str
  end
  
  #Search for what looks like links in a string and does something with it based on block given or arguments given.
  #===Examples
  # str = "asd asd asd asdjklqwejqwer http://www.google.com asdfas df asf"
  # Knj::Strings.html_links(str) #=> "asd asd asd asdjklqwejqwer <a href=\"http://www.google.com\">http://www.google.com</a> asdfas df asf"
  # Knj::Strings.html_links(str){ |data| str.gsub(data[:match][0], "!!!#{data[:match][1]}!!!")} #=> "asd asd asd asdjklqwejqwer !!!www!!! asdfas df asf"
  def self.html_links(str, args = {})
    Knj::Web.html(str).scan(/(http:\/\/([A-z]+)\S*\.([A-z]{2,4})(\S+))/) do |match|
      if block_given?
        str = yield(:str => str, :args => args, :match => match)
      else
        if args["target"]
          html = "<a target=\"#{args["target"]}\""
        else
          html = "<a"
        end
        
        html << " href=\"#{match[0]}\">#{match[0]}</a>"
        str = str.gsub(match[0], html)
      end
    end
    
    return str
  end
  
  #Strips various given characters from a given string.
  #===Examples
  # Knj::Strings.strip("...kasper...", {:right => false, :left => true, :strips => [".", ","]}) #=> "kasper..."
  def self.strip(origstr, args)
    newstr = "#{origstr}"
    
    if !args.key?(:right) or args[:right]
      loop do
        changed = false
        args[:strips].each do |str|
          len = str.length
          endstr = newstr.slice(-len, len)
          next if !endstr
          
          if endstr == str
            changed = true
            newstr = newstr.slice(0..newstr.length-len-1)
          end
        end
        
        break if !changed
      end
    end
    
    if !args.key?(:left) or args[:left]
      loop do
        changed = false
        args[:strips].each do |str|
          len = str.length
          endstr = newstr.slice(0, len)
          next if !endstr
          
          if endstr == str
            changed = true
            newstr = newstr.slice(len..-1)
          end
        end
        
        break if !changed
      end
    end
    
    return newstr
  end
  
  #Returns the module from the given string - even if formed as SomeClass::SomeNewClass.
  def self.const_get_full(str)
    raise "Invalid object: '#{str.class.name}'." if !str.is_a?(String) and !str.is_a?(Symbol)
    module_use = Kernel
    
    str.to_s.scan(/(.+?)(::|$)/) do |match|
      module_use = module_use.const_get(match[0])
    end
    
    return module_use
  end
  
  #Email content may only be 1000 characters long. This method shortens them gracefully.
  def self.email_str_safe(str)
    str = str.to_s
    strcopy = "#{str}"
    
    str.each_line("\n") do |substr_orig|
      substr = "#{substr_orig}"
      next if substr.length <= 1000
      
      lines = []
      
      while substr.length > 1000 do
        whitespace_index = substr.rindex(/\s/, 1000)
        
        if whitespace_index == nil
          lines << substr.slice(0, 1000)
          substr = substr.slice(1000, substr.length)
        else
          lines << substr.slice(0, whitespace_index + 1)
          substr = substr.slice(whitespace_index + 1, substr.length)
        end
      end
      
      lines << substr
      
      strcopy.gsub!(/^#{Regexp.escape(substr_orig)}$/, lines.join("\n"))
    end
    
    return strcopy
  end
  
  #Returns a float as human locaically readable. 1.0 will be 1, 1.5 will be 1.5 and so on.
  def self.float_as_human_logic(floatval)
    raise "Not a float." if !floatval.is_a?(Float)
    
    float_s = floatval.to_s
    parts = float_s.split(".")
    if parts[1].to_i > 0
      return float_s
    else
      return parts[0].to_s
    end
  end
  
  #Returns a short time-format for the given amount of seconds.
  def self.secs_to_human_short_time(secs, args = nil)
    secs = secs.to_i
    
    return "#{secs}s" if secs < 60 and (!args or !args.key?(:secs) or args[:secs])
    
    mins = (secs.to_f / 60.0).floor
    if mins < 60 and (!args or !args.key?(:mins) or args[:mins])
      return "#{mins.to_i}m"
    end
    
    hours = (mins.to_f / 60.0)
    return "#{Knj::Locales.number_out(hours, 1)}t"
  end
  
  #Returns a human readable time-string from a given number of seconds.
  def self.secs_to_human_time_str(secs, args = nil)
    secs = secs.to_i
    hours = (secs.to_f / 3600.0).floor.to_i
    secs = secs - (hours * 3600)
    
    mins = (secs.to_f / 60).floor.to_i
    secs = secs - (mins * 60)
    
    str = "#{"%02d" % hours}:#{"%02d" % mins}"
    
    if !args or !args.key?(:secs) or args[:secs]
      str << ":#{"%02d" % secs}"
    end
    
    return str
  end
  
  #Turns a human readable time-string into a number of seconds.
  def self.human_time_str_to_secs(str)
    match = str.match(/^\s*(\d+)\s*:\s*(\d+)(\s*:\s*(\d+)\s*|)/)
    raise "Could not match string: '#{str}'." if !match
    
    hours = match[1].to_i
    minutes = match[2].to_i
    secs = match[4].to_i
    
    total = (hours * 3600) + (minutes * 60) + secs
    return total
  end
  
  #Same as 'Class#is_a?' but takes a string instead of the actual class. Then it doesnt get autoloaded or anything like that. It can also test against an array containing string-class-names.
  def self.is_a?(obj, str)
    obj_class = obj.class
    str = str.to_s if !str.is_a?(Array)
    
    loop do
      if str.is_a?(Array)
        return true if str.index(obj_class.name.to_s) != nil
      else
        return true if obj_class.name.to_s == str
      end
      
      obj_class = obj_class.superclass
      break if !obj_class
    end
    
    return false
  end
  
  #Takes a string and converts it to a safe string for filenames.
  def self.sanitize_filename(filename)
    return filename.gsub(/[^0-9A-z.\-]/, '_').gsub("\\", "_")
  end
  
  # Removes all non-ASCII parts of a string.
  def self.remove_non_ascii(str, replacement = "") 
    return str.gsub(/\P{ASCII}/, '')
  end
end