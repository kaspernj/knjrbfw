module Knj
	module Php
		def self.is_numeric(n) Float n rescue false end
		
		def self.call_user_func(*paras)
			if paras[0].is_a?(String)
				eval_string = "send(:" + paras[0]
				
				if (paras[1])
					eval_string += ", paras[1]"
				end
				
				eval_string += ")"
				
				eval(eval_string)
			elsif paras[0].is_a?(Array)
				eval_string = "paras[0][0].send(:" + paras[0][1]
				
				if (paras[1])
					eval_string += ", paras[1]"
				end
				
				eval_string += ")"
				
				eval(eval_string)
			else
				raise "Unknown user-func."
			end
		end
		
		def self.print_r(argument, count = 1)
			cstr = argument.class.to_s
			
			if (argument.is_a?(Hash) or cstr == "SQLite3::ResultSet::HashWithTypes" or cstr == "CGI" or cstr == "Knj::Db_row" or cstr == "Apache::Table")
				print argument.class.to_s + "{\n"
				argument.each do |pair|
					i = 0
					while(i < count)
						print "   "
						i += 1
					end
					
					print "[", pair[0], "] => "
					print_r(pair[1], count + 1)
				end
				
				i = 0
				while(i < count - 1)
					print "   "
					i += 1
				end
				
				print "}\n"
			elsif argument.is_a?(Array) or argument.is_a?(MatchData)
				print argument.class.to_s + "{\n"
				
				arr_count = 0
				argument.to_a.each do |i|
					i_spaces = 0
					while(i_spaces < count)
						print "   "
						i_spaces += 1
					end
					
					print "[", arr_count.to_s, "] => "
					print_r(i, count + 1)
					arr_count += 1
				end
				
				i_spaces = 0
				while(i_spaces < count - 1)
					print "   "
					i_spaces += 1
				end
				
				print "}\n"
			elsif argument.is_a?(String) or argument.is_a?(Integer) or argument.is_a?(Fixnum)
				print argument.to_s, "\n"
			else
				#print argument.to_s, "\n"
				print "Unkonwn class: ", argument.class, "\n"
			end
		end
		
		def self.date(date_format, date_object = nil)
			if date_object == nil
				date_object = Time.now
			end
			
			date_format = date_format.gsub("d", "%02d" % date_object.mday)
			date_format = date_format.gsub("m", "%02d" % date_object.mon)
			date_format = date_format.gsub("y", "%02d" % date_object.year.to_s[2,2].to_i)
			date_format = date_format.gsub("Y", "%04d" % date_object.year)
			date_format = date_format.gsub("H", "%02d" % date_object.hour)
			date_format = date_format.gsub("i", "%02d" % date_object.min)
			date_format = date_format.gsub("s", "%02d" % date_object.sec)
			
			return date_format
		end
		
		def self.gtext(string)
			return GetText._(string)
		end
		
		def self.number_format(number, precision, seperator, delimiter)
			if number.is_a?(Float)
				number = number.to_f
			end
			
			number = sprintf("%." + precision.to_s + "f", number)
			
			number = number.gsub(%r{([0-9]{3}(?=([0-9])))}, "\\1,")
			
			number = number.gsub(",", "comma").gsub(".", "dot")
			number = number.gsub("comma", delimiter).gsub("dot", seperator)
			
			return number
		end
		
		def self.ucwords(string)
			return string.to_s.split(" ").select {|w| w.capitalize! || w }.join(" ")
		end
		
		def self.htmlspecialchars(string)
			require("cgi")
			return CGI.escapeHTML(string)
		end
		
		def self.isset(var)
			if var == nil or var == false
				return false
			end
			
			return true
		end
		
		def self.strpos(haystack, needle)
			if !haystack
				return false
			end
			
			if !haystack.to_s.include?(needle)
				return false
			end
			
			return haystack.index(needle)
		end
		
		def self.substr(string, from, to = -1)
			return string.to_s.slice(from.to_i, to.to_i)
		end
		
		def self.md5(string)
			return Digest::MD5.hexdigest(string)
		end
		
		def self.header(headerstr)
			match = headerstr.to_s.match(/(.*): (.*)/)
			
			if !match
				raise "Couldnt parse header."
			end
			
			Apache.request.headers_out[match[1]] = match[2]
		end
		
		def self.nl2br(string)
			return string.to_s.gsub("\n", "<br />\n")
		end
		
		def self.urldecode(string)
			require("cgi")
			return CGI.unescape(string)
		end
		
		def self.urlencode(string)
			require("cgi")
			return CGI.escape(string)
		end
		
		def self.file_put_contents(filepath, content)
			filepath.untaint
			File.open(filepath, "w") do |file|
				file.write content
			end
		end
		
		def self.file_get_contents(filepath)
			return File.read(filepath)
		end
		
		def self.strtotime(date_string)
			return Time.local(*ParseDate.parsedate(date_string))
		end
		
		def self.class_exists(classname)
			begin
				Kernel.const_get(classname)
				return true
			rescue Exception
				return false
			end
		end
		
		def self.html_entity_decode(string)
			return CGI::unescapeHTML(string.to_s)
		end
	end
end