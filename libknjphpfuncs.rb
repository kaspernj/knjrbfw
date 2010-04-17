def is_numeric(n) Float n rescue false end

def call_user_func(*paras)
	if (paras[0].class.to_s == "String")
		eval_string = "send(:" + paras[0]
		
		if (paras[1])
			eval_string += ", paras[1]"
		end
		
		eval_string += ")"
		
		eval(eval_string)
	elsif (paras[0].class.to_s == "Array")
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

def print_r(argument, count = 1)
	if (argument.is_a?(Hash) or argument.class.to_s == "SQLite3::ResultSet::HashWithTypes" or argument.class.to_s == "CGI" or argument.is_a?(Knj::Db_row))
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
	elsif(argument.is_a?(Array))
		print argument.class.to_s + "{\n"
		arr_count = 0
		argument.each{ |i|
			i_spaces = 0
			while(i_spaces < count)
				print "   "
				i_spaces += 1
			end
			
			print "[", arr_count.to_s, "] => "
			print_r(i, count + 1)
			arr_count += 1
		}
		
		i_spaces = 0
		while(i_spaces < count - 1)
			print "   "
			i_spaces += 1
		end
		
		print "}\n"
	elsif(argument.class.to_s == "String" or argument.class.to_s == "Integer" or argument.class.to_s == "Fixnum")
		print argument, "\n"
	else
		#print argument.to_s, "\n"
		print "Unkonwn class: ", argument.class, "\n"
	end
end

def date(date_format, date_object = nil)
	if date_object == nil
		date_object = Time.now
	end
	
	date_format = date_format.gsub("d", "%02d" % date_object.mday)
	date_format = date_format.gsub("m", "%02d" % date_object.mon)
	date_format = date_format.gsub("y", "%02d" % date_object.year.to_s[2,2].to_i)
	date_format = date_format.gsub("Y", "%04d" % date_object.year)
	
	return date_format
end

def gtext(string)
	return GetText._(string)
end

def number_format(number, precision, seperator, delimiter)
	if (number.class.to_s != "Float")
		number = number.to_f
	end
	
	number = sprintf("%." + precision.to_s + "f", number)
	
	number = number.gsub(%r{([0-9]{3}(?=([0-9])))}, "\\1,")
	
	number = number.gsub(",", "comma").gsub(".", "dot")
	number = number.gsub("comma", delimiter).gsub("dot", seperator)
	
	return number
end

def ucwords(string)
	return string.to_s.split(" ").select {|w| w.capitalize! || w }.join(" ")
end

def htmlspecialchars(string)
	require("cgi")
	return CGI.escapeHTML(string)
end

def isset(var)
	if (var == nil or var == false)
		return false
	end
	
	return true
end

def strpos(haystack, needle)
	if (!haystack)
		return false
	end
	
	if (!haystack.to_s.include?(needle))
		return false
	end
	
	return haystack.index(needle)
end