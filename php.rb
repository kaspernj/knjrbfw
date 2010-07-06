module Knj
	module Php
		def self.is_numeric(n) Float n rescue false end
		
		def self.call_user_func(*paras)
			if paras[0].is_a?(String)
				send_paras = [paras[0].to_sym]
				
				if paras[1]
					send_paras << paras[1]
				end
				
				send(*send_paras)
			elsif paras[0].is_a?(Array)
				send_paras = [paras[0][1].to_sym]
				
				if paras[1]
					send_paras << paras[1]
				end
				
				paras[0][0].send(*send_paras)
			else
				raise "Unknown user-func."
			end
		end
		
		def self.print_r(argument, ret = false, count = 1)
			retstr = ""
			cstr = argument.class.to_s
			supercl = argument.class.superclass
			
			if supercl
				superstr = supercl.to_s
			end
			
			if argument.is_a?(Hash) or supercl.is_a?(Hash) or cstr == "SQLite3::ResultSet::HashWithTypes" or cstr == "CGI" or cstr == "Knj::Db_row" or cstr == "Apache::Table" or superstr == "Knj::Db_row"
				retstr += argument.class.to_s + "{\n"
				argument.each do |pair|
					i = 0
					while(i < count)
						retstr += "   "
						i += 1
					end
					
					retstr += "[" + pair[0] + "] => "
					retstr += print_r(pair[1], true, count + 1).to_s
				end
				
				i = 0
				while(i < count - 1)
					retstr += "   "
					i += 1
				end
				
				retstr += "}\n"
			elsif argument.is_a?(MatchData) or argument.is_a?(Array) or cstr == "Array" or supercl.is_a?(Array)
				retstr += argument.class.to_s + "{\n"
				
				arr_count = 0
				argument.to_a.each do |i|
					i_spaces = 0
					while(i_spaces < count)
						retstr += "   "
						i_spaces += 1
					end
					
					retstr += "[" + arr_count.to_s + "] => "
					retstr += print_r(i, true, count + 1).to_s
					arr_count += 1
				end
				
				i_spaces = 0
				while(i_spaces < count - 1)
					retstr += "   "
					i_spaces += 1
				end
				
				retstr += "}\n"
			elsif argument.is_a?(String) or argument.is_a?(Integer) or argument.is_a?(Fixnum)
				retstr += argument.to_s + "\n"
			else
				#print argument.to_s, "\n"
				retstr += "Unknown class: " + cstr + "\n"
			end
			
			if ret.is_a?(TrueClass)
				return retstr
			else
				print retstr
			end
		end
		
		def self.date(date_format, date_unixt = nil)
			if date_unixt == nil
				date_unixt = Time.now.to_i
			end
			
			date_object = Time.at(date_unixt.to_i)
			
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
		
		def self.gettext(string)
			return GetText._(string)
		end
		
		def self.number_format(number, precision = 2, seperator = ".", delimiter = ",")
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
			return Knj::Php.ucwords(string)
		end
		
		def self.ucwords(string)
			return string.to_s.split(" ").select {|w| w.capitalize! || w }.join(" ")
		end
		
		def self.htmlspecialchars(string)
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
			string = string.to_s.slice(from.to_i, to.to_i)
			
			ic = Iconv.new("UTF-8//IGNORE", "UTF-8")
			string = ic.iconv(string + "  ")[0..-2]
			
			return string
		end
		
		def self.md5(string)
			return Digest::MD5.hexdigest(string.to_s)
		end
		
		def self.header(headerstr)
			match = headerstr.to_s.match(/(.*): (.*)/)
			
			if !match
				raise "Couldnt parse header."
			end
			
			Apache.request.headers_out[match[1]] = match[2]
			
			if $cgi.is_a?(CGI)
				$cgi.header(match[1] => match[2])
			end
		end
		
		def header(str)
			return Knj::Php.header(str)
		end
		
		def self.nl2br(string)
			return string.to_s.gsub("\n", "<br />\n")
		end
		
		def self.urldecode(string)
			return CGI.unescape(string)
		end
		
		def self.urlencode(string)
			return CGI.escape(string.to_s)
		end
		
		def self.file_put_contents(filepath, content)
			File.open(filepath.untaint, "w") do |file|
				file.write content
			end
		end
		
		def self.file_get_contents(filepath)
			return File.read(filepath.untaint)
		end
		
		def self.file_exists(filepath)
			if File.exists?(filepath.to_s.untaint)
				return true
			end
			
			return false
		end
		
		def self.strtotime(date_string, cur = nil)
			if !cur
				cur = Time.new
			else
				cur = Time.at(cur)
			end
			
			date_string = date_string.to_s.downcase
			
			if date_string.match(/[0-9]+-[0-9]+-[0-9]+/i)
				return Time.local(*ParseDate.parsedate(date_string)).to_i
			end
			
			date_string.scan(/((\+|-)([0-9]+) (\S+))/) do |match|
				timestr = match[3]
				number = match[2].to_i
				mathval = match[1]
				add = nil
				
				if timestr == "years" or timestr == "year"
					add = ((number.to_i * 3600) * 24) * 365
				elsif timestr == "months" or timestr == "month"
					add = ((number.to_i * 3600) * 24) * 30
				elsif timestr == "weeks" or timestr == "week"
					add = (number.to_i * 3600) * 24 * 7
				elsif timestr == "days" or timestr == "day"
					add = (number.to_i * 3600) * 24
				elsif timestr == "hours" or timestr == "hour"
					add = number.to_i * 3600
				elsif timestr == "minutes" or timestr == "minute" or timestr == "min" or timestr == "mints"
					add = number.to_i * 60
				elsif timestr == "seconds" or timestr == "second" or timestr == "sec" or timestr == "secs"
					add = number.to_i
				end
				
				if mathval == "+"
					cur += add
				elsif mathval == "-"
					cur -= add
				end
			end
			
			return cur.to_i
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
			string = CGI.unescapeHTML(string.to_s)
			string = string.gsub("&oslash;", "ø").gsub("&aelig;", "æ").gsub("&aring;", "å")
			
			return string
		end
		
		def self.strip_tags(htmlstr)
			htmlstr.scan(/(<([\/A-z]+).*?>)/) do |match|
				htmlstr = htmlstr.gsub(match[0], "")
			end
			
			return htmlstr
		end
		
		def self.die(msg)
			print msg
			exit
		end
		
		def self.fopen(filename, mode)
			begin
				return File.open(filename, mode)
			rescue Exception
				return false
			end
		end
		
		def self.fwrite(fp, str)
			begin
				fp.print str
			rescue Exception
				return false
			end
			
			return true
		end
		
		def self.fputs(fp, str)
			begin
				fp.print str
			rescue Exception
				return false
			end
			
			return true
		end
		
		def self.fread(fp, length = 4096)
			return fp.read(length)
		end
		
		def self.fgets(fp, length = 4096)
			return fp.read(length)
		end
		
		def self.fclose(fp)
			fp.close
		end
		
		def self.move_uploaded_file(tmp_path, new_path)
			FileUtils.mv(tmp_path.untaint, new_path.untaint)
		end
		
		def self.utf8_encode(str)
			begin
				return Iconv.conv("iso-8859-1", "utf-8", str.to_s)
			rescue
				return Iconv.conv("iso-8859-1//ignore", "utf-8", str.to_s + "  ").slice(0..-2)
			end
		end
		
		def self.utf8_decode(str)
			begin
				return Iconv.conv("utf-8", "iso-8859-1", str.to_s)
			rescue
				return Iconv.conv("utf-8//ignore", "iso-8859-1", str.to_s)
			end
		end
		
		def self.setcookie(cname, cvalue, expire = nil, domain = nil)
			paras = {
				"name" => cname,
				"value" => cvalue
			}
			
			if expire
				paras["expires"] = Time.at(expire)
			end
			
			if domain
				paras["domain"] = domain
			end
			
			cookie = CGI::Cookie.new(paras)
			$_CGI.out("cookie" => cookie){""}
			
			if $_COOKIE
				$_COOKIE[cname] = cvalue
			end
		end
		
		def self.explode(expl, strexp)
			return strexp.to_s.split(expl)
		end
		
		def self.dirname(filename)
			File.dirname(filename)
		end
		
		def self.chdir(dirname)
			Dir.chdir(dirname)
		end
		
		def include_once(filename)
			require filename
		end
		
		def require_once(filename)
			require filename
		end
		
		def echo(string)
			print string
		end
		
		def msgbox(title, msg, type)
			Knj::Gtk2.msgbox(msg, type, title)
		end
		
		def count(array)
			return array.length
		end
		
		Knj::Php.singleton_methods.each do |methodname|
			define_method methodname.to_sym do |*paras|
				return Knj::Php.send(methodname, *paras)
			end
		end
	end
end

