# coding: utf-8

module Knj::Php
	def self.is_numeric(n) Float n rescue false end
	
	def self.call_user_func(*paras)
		if paras[0].is_a?(String)
			send_paras = [paras[0].to_sym]
			send_paras << paras[1] if paras[1]
			send(*send_paras)
		elsif paras[0].is_a?(Array)
			send_paras = [paras[0][1].to_sym]
			send_paras << paras[1] if paras[1]
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
		
		if argument.is_a?(Hash) or supercl.is_a?(Hash) or cstr == "Knjappserver::Session_accessor" or cstr == "SQLite3::ResultSet::HashWithTypes" or cstr == "CGI" or cstr == "Knj::Db_row" or cstr == "Apache::Table" or superstr == "Knj::Db_row"
			retstr += argument.class.to_s + "{\n"
			argument.each do |pair|
				i = 0
				while(i < count)
					retstr += "   "
					i += 1
				end
				
				if pair[0].is_a?(Symbol)
					keystr = ":#{pair[0].to_s}"
				else
					keystr = pair[0].to_s
				end
				
				retstr += "[#{keystr}] => "
				retstr += print_r(pair[1], true, count + 1).to_s
			end
			
			i = 0
			while(i < count - 1)
				retstr += "   "
				i += 1
			end
			
			retstr += "}\n"
		elsif cstr == "Dictionary"
			retstr += argument.class.to_s + "{\n"
			argument.each do |key, val|
				i = 0
				while(i < count)
					retstr += "   "
					i += 1
				end
				
				if key.is_a?(Symbol)
					keystr = ":#{key.to_s}"
				else
					keystr = key.to_s
				end
				
				retstr += "[#{keystr}] => "
				retstr += Knj::Php.print_r(val, true, count + 1).to_s
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
		elsif cstr == "WEBrick::HTTPUtils::FormData"
			retstr += "{#{argument.class.to_s}}"
		elsif argument.is_a?(String) or argument.is_a?(Integer) or argument.is_a?(Fixnum) or argument.is_a?(Float)
			retstr += argument.to_s + "\n"
		elsif argument.is_a?(Symbol)
			retstr += ":#{argument.to_s}"
		elsif argument.is_a?(Exception)
			retstr += "#\{#{argument.class.to_s}: #{argument.message}}\n"
		elsif cstr == "Knj::Unix_proc"
			retstr += "#{argument.class.to_s}::data - "
			retstr += print_r(argument.data, true, count).to_s
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
	
	def self.gtext(string)
		return GetText._(string)
	end
	
	def self.gettext(string)
		return GetText._(string)
	end
	
	def self.number_format(number, precision = 2, seperator = ".", delimiter = ",")
		if !number.is_a?(Float)
			number = number.to_f
		end
		
		if number < 1
			return sprintf("%.#{precision.to_s}f", number).gsub(".", seperator)
		end
		
		number = sprintf("%.#{precision.to_s}f", number)
		
		#thanks for jmoses wrote some of tsep-code: http://snippets.dzone.com/posts/show/693
		st = number.reverse
		r = ""
		max = if st[-1].chr == '-'
			st.size - 1
		else
			st.size
		end
		
		if st.to_i == st.to_f
			1.upto(st.size) do |i|
				r << st[i-1].chr if st[i-1].chr != "."
				r << ',' if i%3 == 0 and i < max
			end
		else
			start = nil
			1.upto(st.size) do |i|
				r << st[i-1].chr
				start = 0 if r[-1].chr == '.' and not start
				if start
					r << ',' if start % 3 == 0 and start != 0  and i < max
					start += 1
				end
			end
		end
		
		numberstr = r.to_s.reverse
		numberstr = numberstr.gsub(",", "comma").gsub(".", "dot")
		numberstr = numberstr.gsub("comma", delimiter).gsub("dot", seperator)
		
		return numberstr
	end
	
	def self.ucwords(string)
		return string.to_s.split(" ").select {|w| w.capitalize! || w }.join(" ")
	end
	
	def self.htmlspecialchars(string)
		return CGI.escapeHTML(string)
	end
	
	def self.isset(var)
		return false if var == nil or var == false
		return true
	end
	
	def self.strpos(haystack, needle)
		return false if !haystack
		return false if !haystack.to_s.include?(needle)
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
		if match
			key = match[1]
			value = match[2]
		else
			#HTTP/1.1 404 Not Found
			
			match_status = headerstr.to_s.match(/^HTTP\/[0-9\.]+ ([0-9]+) (.+)$/)
			if match_status
				key = "Status"
				value = match_status[1] + " " + match_status[2]
			else
				raise "Couldnt parse header."
			end
		end
		
		sent = false
		
		if Knj::Php.class_exists("Apache")
			Apache.request.headers_out[key] = value
			sent = true
		end
		
		begin
			_httpsession.eruby.header(key, value) #This is for knjAppServer - knj.
			sent = true
		rescue NameError => e
			if $knj_eruby
				$knj_eruby.header(key, value)
				sent = true
			elsif $cgi.is_a?(CGI)
				sent = true
				$cgi.header(key => value)
			elsif $_CGI.is_a?(CGI)
				sent = true
				$_CGI.header(key => value)
			end
		end
		
		return sent
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
		filepath = filepath.to_s
		
		if http_match = filepath.match(/^http(s|):\/\/([A-z_\d\.]+)(|:(\d+))(\/(.+))$/)
			if http_match[4].to_s.length > 0
				port = http_match[4].to_i
			end
			
			args = {
				"host" => http_match[2]
			}
			
			if http_match[1] == "s"
				args["ssl"] = true
				args["validate"] = false
				
				if !port
					port = 443
				end
			end
			
			args["port"] = port if port
			
			http = Knj::Http.new(args)
			data = http.get(http_match[5])
			return data["data"]
		end
		
		return File.read(filepath.untaint)
	end
	
	def self.is_file(filepath)
		begin
			if File.file?(filepath)
				return true
			end
		rescue Exception
			return false
		end
		
		return false
	end
	
	def self.is_dir(filepath)
		begin
			if File.directory?(filepath)
				return true
			end
		rescue Exception
			return false
		end
		
		return false
	end
	
	def self.unlink(filepath)
		FileUtils.rm(filepath)
	end
	
	def self.file_exists(filepath)
		return true if File.exists?(filepath.to_s.untaint)
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
			begin
				return Time.local(*ParseDate.parsedate(date_string)).to_i
			rescue
				return 0
			end
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
		string = string.gsub("&oslash;", "ø").gsub("&aelig;", "æ").gsub("&aring;", "å").gsub("&euro;", "€")
		return string
	end
	
	def self.strip_tags(htmlstr)
		htmlstr.scan(/(<([\/A-z]+).*?>)/) do |match|
			htmlstr = htmlstr.gsub(match[0], "")
		end
		
		return htmlstr.gsub("&nbsp;", " ")
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
			"value" => cvalue,
			"path" => "/"
		}
		paras["expires"] = Time.at(expire) if expire
		paras["domain"] = domain if domain
		
		cookie = CGI::Cookie.new(paras)
		Knj::Php.header("Set-Cookie: #{cookie.to_s}")
		
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
	
	def self.include_once(filename)
		require filename
	end
	
	def self.require_once(filename)
		require filename
	end
	
	def self.echo(string)
		print string
	end
	
	def self.msgbox(title, msg, type)
		Knj::Gtk2.msgbox(msg, type, title)
	end
	
	def self.count(array)
		return array.length
	end
	
	def self.json_encode(obj)
		return JSON.generate(obj)
	end
	
	def self.json_decode(data)
		return JSON.parse(data)
	end
	
	def self.time
		return Time.new.to_i
	end
	
	def self.microtime(get_as_float = false)
		microtime = Time.now.to_f
		
		return microtime if get_as_float
		
		splitted = microtime.to_s.split(",")
		return "#{splitted[0]} #{splitted[1]}"
	end
	
	def self.mktime(hour = nil, min = nil, sec = nil, date = nil, month = nil, year = nil, is_dst = -1)
		cur_time = Time.new
		
		hour = cur_time.hour if hour == nil
		min = cur_time.min if min == nil
		sec = cur_time.sec if sec == nil
		date = cur_time.date if date == nil
		month = cur_time.month if month == nil
		year = cur_time.year if year == nil
		
		new_time = Datestamp.from_dbstr("#{year.to_s}-#{month.to_s}-#{date.to_s} #{hour.to_s}:#{min.to_s}:#{sec.to_s}")
		return new_time.to_i
	end
	
	def self.date(date_format, date_unixt = nil)
		date_unixt = Time.now.to_i if date_unixt == nil
		
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
	
	def self.basename(filepath)
		splitted = filepath.to_s.split("/").last
		return false if !splitted
		
		ret = splitted.split(".")
		ret.delete(ret.last)
		return ret.join(".")
	end
	
	def self.pathinfo(filepath)
		filepath = filepath.to_s
		
		dirname = File.dirname(filepath)
		dirname = "" if dirname == "."
		
		return {
			"dirname" => dirname,
			"basename" => self.basename(filepath),
			"extension" => filepath.split(".").last,
			"filename" => filepath.split("/").last
		}
	end
	
	def self.realpath(pname)
		begin
			return Pathname.new(pname.to_s).realpath.to_s
		rescue => e
			return false
		end
	end
	
	# Returns the scripts current memory usage.
	def self.memory_get_usage
		# FIXME: This only works on Linux at the moment, since we are doing this by command line - knj.
		memory_usage = `ps -o rss= -p #{Process.pid}`.to_i * 1024
		return memory_usage
	end
	
	# Should return the peak usage of the running script, but I have found no way to detect this... Instead returns the currently memory usage.
	def self.memory_get_peak_usage
		return self.memory_get_usage
	end
	
	Knj::Php.singleton_methods.each do |methodname|
		define_method methodname.to_sym do |*paras|
			return Knj::Php.send(methodname, *paras)
		end
	end
end