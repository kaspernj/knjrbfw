module Knj::Strings
	def self.UnixSafe(tha_string)
		return tha_string.to_s.gsub(" ", "\\ ").gsub("&", "\&").gsub("(", "\\(").gsub(")", "\\)").gsub('"', '\"').gsub("\n", "\"\n\"")
	end
	
	def self.unixsafe(string)
		return Knj::Strings.UnixSafe(string)
	end
	
	def self.searchstring(string)
		words = []
		string = string.to_s
		
		matches = string.scan /(\"(.+?)\")/
		matches.each do |matcharr|
			word = matcharr[1]
			
			if word and word.length > 0
				words << matcharr[1]
				string = string.gsub(matcharr[0], "")
			end
		end
		
		string.split(/\s/).each do |word|
			words << word if word and word.length > 0
		end
		
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
	
	def self.js_safe(str)
		return str.gsub("\r", "").gsub("\n", "\\n").gsub('"', '\"');
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
		
		return str_no if !value
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
        
        html += " href=\"#{match[0]}\">#{match[0]}</a>"
        
        str = str.gsub(match[0], html)
      end
    end
    
    return str
	end
end