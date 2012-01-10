#encoding: utf-8

module Knj::Strings
  def self.UnixSafe(tha_string)
    return tha_string.to_s.gsub(" ", "\\ ").gsub("&", "\&").gsub("(", "\\(").gsub(")", "\\)").gsub('"', '\"').gsub("\n", "\"\n\"")
  end
  
  def self.unixsafe(string)
    return Knj::Strings.UnixSafe(string)
  end
  
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
  
  def self.is_email?(str)
    return true if str.to_s.match(/^\S+@\S+\.\S+$/)
    return false
  end
  
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
  
  def self.yn_str(value, str_yes, str_no)
    value = value.to_i if Knj::Php.is_numeric(value)
    
    if value.is_a?(Integer)
      if value == 0
        return str_no
      else
        return str_yes
      end
    end
    
    return str_no if !value or value == "no"
    return str_yes
  end
  
  def self.shorten(str, maxlength)
    str = str.to_s
    str = str.slice(0..(maxlength - 1)).strip + "..." if str.length > maxlength
    return str
  end
  
  def self.html_links(str, args = {})
    str.to_s.html.scan(/(http:\/\/([A-z]+)\S*\.([A-z]{2,4})(\S+))/) do |match|
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
  
  def self.strip(origstr, args)
    newstr = "#{origstr}<br>"
    
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
    module_use = Kernel
    
    str.scan(/(.+?)(::|$)/) do |match|
      module_use = module_use.const_get(match[0])
    end
    
    return module_use
  end
  
  #Email content may only be 1000 characters wrong. This method shortens them gracefully.
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
end