# coding: utf-8

module Knj::Php
	def is_numeric(n) Float n rescue false end
	
	def call_user_func(*paras)
		if paras[0].is_a?(String)
			send_paras = [paras[0].to_sym]
			send_paras << paras[1] if paras[1]
			send(*send_paras)
		elsif paras[0].is_a?(Array)
			send_paras = [paras[0][1].to_sym]
			send_paras << paras[1] if paras[1]
			paras[0][0].send(*send_paras)
		else
			raise "Unknown user-func: '#{paras[0].class.name}'."
		end
	end
	
	def print_r(argument, ret = false, count = 1)
		retstr = ""
		cstr = argument.class.to_s
		supercl = argument.class.superclass
		
		if supercl
			superstr = supercl.to_s
		end
		
		if argument.is_a?(Hash) or supercl.is_a?(Hash) or cstr == "Knjappserver::Session_accessor" or cstr == "SQLite3::ResultSet::HashWithTypes" or cstr == "CGI" or cstr == "Knj::Db_row" or cstr == "Knj::Datarow" or cstr == "Apache::Table" or superstr == "Knj::Db_row" or superstr == "Knj::Datarow" or argument.respond_to?(:to_hash)
			if argument.respond_to?(:to_hash)
				argument_use = argument.to_hash
			else
				argument_use = argument
			end
			
			retstr += argument.class.to_s + "{\n"
			argument_use.each do |pair|
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
			retstr += ":#{argument.to_s}\n"
		elsif argument.is_a?(Exception)
			retstr += "#\{#{argument.class.to_s}: #{argument.message}}\n"
		elsif cstr == "Knj::Unix_proc"
			retstr += "#{argument.class.to_s}::data - "
			retstr += print_r(argument.data, true, count).to_s
    elsif cstr == "Thread"
      retstr += "#{argument.class.to_s} - "
      
      hash = {}
      argument.keys.each do |key|
        hash[key] = argument[key]
      end
      
      retstr += print_r(hash, true, count).to_s
    elsif cstr == "Class"
      retstr += "#{argument.class.to_s} - "
      hash = {"name" => argument.name}
      retstr += print_r(hash, true, count).to_s
    elsif cstr == "URI::Generic"
      retstr += "#{argument.class.to_s}{\n"
      methods = [:host, :port, :scheme, :path]
      count += 1
      methods.each do |method|
        i_spaces = 0
        while(i_spaces < count - 1)
          retstr += "   "
          i_spaces += 1
        end
        
        retstr += "#{method}: #{argument.send(method)}\n"
      end
      
      count -= 1
      
      i = 0
      while(i < count - 1)
        retstr += "   "
        i += 1
      end
      
      retstr += "}\n"
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
	
	def gtext(string)
		return GetText._(string)
	end
	
	def gettext(string)
		return GetText._(string)
	end
	
	def number_format(number, precision = 2, seperator = ".", delimiter = ",")
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
	
	def ucwords(string)
		return string.to_s.split(" ").select {|w| w.capitalize! || w }.join(" ")
	end
	
	def strtoupper(str)
    return str.to_s.upcase
	end
	
	def strtolower(str)
    return str.to_s.downcase
	end
	
	def htmlspecialchars(string)
		return Knj::Web.html(string)
	end
	
	def isset(var)
		return false if var == nil or var == false
		return true
	end
	
	def strpos(haystack, needle)
		return false if !haystack
		return false if !haystack.to_s.include?(needle)
		return haystack.index(needle)
	end
	
	def substr(string, from, to = -1)
		string = string.to_s.slice(from.to_i, to.to_i)
		
		if Knj::Php.class_exists("Iconv")
      ic = Iconv.new("UTF-8//IGNORE", "UTF-8")
      string = ic.iconv(string + "  ")[0..-2]
    end
		
		return string
	end
	
	def md5(string)
		return Digest::MD5.hexdigest(string.to_s)
	end
	
	def header(headerstr)
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
			elsif $cgi.class.name == "CGI"
				sent = true
				$cgi.header(key => value)
			elsif $_CGI.class.name == "CGI"
				sent = true
				$_CGI.header(key => value)
			end
		end
		
		return sent
	end
	
	def nl2br(string)
		return string.to_s.gsub("\n", "<br />\n")
	end
	
  def urldecode(string)
    return Knj::Web.urldec(string)
  end
  
  def urlencode(string)
    return Knj::Web.urlenc(string)
  end
  
  def parse_str(str, hash)
    CGI.parse(str).each do |key, val|
      hash[key] = val
    end
  end
	
	def file_put_contents(filepath, content)
		File.open(filepath.untaint, "w") do |file|
			file.write(content)
		end
	end
	
	def file_get_contents(filepath)
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
	
	def is_file(filepath)
		begin
			if File.file?(filepath)
				return true
			end
		rescue Exception
			return false
		end
		
		return false
	end
	
	def is_dir(filepath)
		begin
			if File.directory?(filepath)
				return true
			end
		rescue Exception
			return false
		end
		
		return false
	end
	
	def unlink(filepath)
		FileUtils.rm(filepath)
	end
	
	def file_exists(filepath)
		return true if File.exists?(filepath.to_s.untaint)
		return false
	end
	
	def strtotime(date_string, cur = nil)
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
	
	def class_exists(classname)
		begin
			Kernel.const_get(classname)
			return true
		rescue Exception
			return false
		end
	end
	
	def html_entity_decode(string)
		string = Knj::Web.html(string)
		string = string.gsub("&oslash;", "ø").gsub("&aelig;", "æ").gsub("&aring;", "å").gsub("&euro;", "€").gsub("#39;", "'")
		return string
	end
	
	def strip_tags(htmlstr)
		htmlstr.scan(/(<([\/A-z]+).*?>)/) do |match|
			htmlstr = htmlstr.gsub(match[0], "")
		end
		
		return htmlstr.gsub("&nbsp;", " ")
	end
	
	def die(msg)
		print msg
		exit
	end
	
	def fopen(filename, mode)
		begin
			return File.open(filename, mode)
		rescue Exception
			return false
		end
	end
	
	def fwrite(fp, str)
		begin
			fp.print str
		rescue Exception
			return false
		end
		
		return true
	end
	
	def fputs(fp, str)
		begin
			fp.print str
		rescue Exception
			return false
		end
		
		return true
	end
	
	def fread(fp, length = 4096)
		return fp.read(length)
	end
	
	def fgets(fp, length = 4096)
		return fp.read(length)
	end
	
	def fclose(fp)
		fp.close
	end
	
	def move_uploaded_file(tmp_path, new_path)
		FileUtils.mv(tmp_path.untaint, new_path.untaint)
	end
	
	def utf8_encode(str)
		str = str.to_s if str.respond_to?(:to_s)
		require "iconv" if RUBY_PLATFORM == "java" #This fixes a bug in JRuby where Iconv otherwise would not be detected.
		
		if str.respond_to?(:encode)
			return str.encode("iso-8859-1", "utf-8")
		elsif Knj::Php.class_exists("Iconv")
			begin
				return Iconv.conv("iso-8859-1", "utf-8", str)
			rescue
				return Iconv.conv("iso-8859-1//ignore", "utf-8", str + "  ").slice(0..-2)
			end
		else
			raise "Could not figure out how to utf8-encode string."
		end
	end
	
	def utf8_decode(str)
		str = str.to_s if str.respond_to?(:to_s)
		require "iconv" if RUBY_PLATFORM == "java" #This fixes a bug in JRuby where Iconv otherwise would not be detected.
		
		if str.respond_to?(:encode)
			return str.encode("utf-8", "iso-8859-1")
		elsif Knj::Php.class_exists("Iconv")
			begin
				return Iconv.conv("utf-8", "iso-8859-1", str.to_s)
			rescue
				return Iconv.conv("utf-8//ignore", "iso-8859-1", str.to_s)
			end
		else
			raise "Could not figure out how to utf8-decode string."
		end
	end
	
	def setcookie(cname, cvalue, expire = nil, domain = nil)
		args = {
			"name" => cname,
			"value" => cvalue,
			"path" => "/"
		}
		args["expires"] = Time.at(expire) if expire
		args["domain"] = domain if domain
		
		begin
      _kas.cookie(args)
		rescue NameError
      cookie = CGI::Cookie.new(args)
      status = Knj::Php.header("Set-Cookie: #{cookie.to_s}")
      $_COOKIE[cname] = cvalue if $_COOKIE
    end
    
		return status
	end
	
	def explode(expl, strexp)
		return strexp.to_s.split(expl)
	end
	
	def dirname(filename)
		File.dirname(filename)
	end
	
	def chdir(dirname)
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
	
	def json_encode(obj)
    if Knj::Php.class_exists("Rho")
      return Rho::JSON.generate(obj)
    elsif Knj::Php.class_exists("JSON")
      return JSON.generate(obj)
    else
      raise "Could not figure out which JSON lib to use."
    end
	end
	
	def json_decode(data)
    raise "String was not given to 'Knj::Php.json_decode'." if !data.is_a?(String)
    
    if Knj::Php.class_exists("Rho")
      return Rho::JSON.parse(data)        
    elsif Knj::Php.class_exists("JSON")  
      return JSON.parse(data)
    else
      raise "Could not figure out which JSON lib to use."
    end
	end
	
	def time
		return Time.new.to_i
	end
	
	def microtime(get_as_float = false)
		microtime = Time.now.to_f
		
		return microtime if get_as_float
		
		splitted = microtime.to_s.split(",")
		return "#{splitted[0]} #{splitted[1]}"
	end
	
	def mktime(hour = nil, min = nil, sec = nil, date = nil, month = nil, year = nil, is_dst = -1)
		cur_time = Time.new
		
		hour = cur_time.hour if hour == nil
		min = cur_time.min if min == nil
		sec = cur_time.sec if sec == nil
		date = cur_time.date if date == nil
		month = cur_time.month if month == nil
		year = cur_time.year if year == nil
		
		new_time = Knj::Datet.in("#{year.to_s}-#{month.to_s}-#{date.to_s} #{hour.to_s}:#{min.to_s}:#{sec.to_s}")
		return new_time.to_i
	end
	
	def date(date_format, date_unixt = nil)
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
	
	def basename(filepath)
		splitted = filepath.to_s.split("/").last
		return false if !splitted
		
		ret = splitted.split(".")
		ret.delete(ret.last)
		return ret.join(".")
	end
	
	def base64_encode(str)
		return Base64.encode64(str.to_s)
	end
	
	def base64_decode(str)
		return Base64.decode64(str.to_s)
	end
	
	def pathinfo(filepath)
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
	
	def realpath(pname)
		begin
			return Pathname.new(pname.to_s).realpath.to_s
		rescue => e
			return false
		end
	end
	
	# Returns the scripts current memory usage.
	def memory_get_usage
		# FIXME: This only works on Linux at the moment, since we are doing this by command line - knj.
		memory_usage = `ps -o rss= -p #{Process.pid}`.to_i * 1024
		return memory_usage
	end
	
	# Should return the peak usage of the running script, but I have found no way to detect this... Instead returns the currently memory usage.
	def memory_get_peak_usage
		return self.memory_get_usage
	end
	
	def ip2long(ip)
		return IPAddr.new(ip).to_i
	end
	
	# Thanks to this link for the following functions: http://snippets.dzone.com/posts/show/4509
	def long2ip(long)
		ip = []
		4.times do |i|
			ip.push(long.to_i & 255)
			long = long.to_i >> 8
		end
		
		ip.reverse.join(".")
	end
	
	def gzcompress(str, level = 3)
		zstream = Zlib::Deflate.new
		gzip_str = zstream.deflate(str.to_s, Zlib::FINISH)
		zstream.close
		
		return gzip_str
	end
	
	def gzuncompress(str, length = 0)
		zstream = Zlib::Inflate.new
		plain_str = zstream.inflate(str.to_s)
		zstream.finish
		zstream.close
		
		return plain_str.to_s
	end
	
	#Sort methods.
	def ksort(hash)
    nhash = hash.sort do |a, b|
      a[0] <=> b[0]
    end
    
    newhash = {}
    nhash.each do |val|
      newhash[val[0]] = val[1][0]
    end
    
    return newhash
	end
	
  module_function(*instance_methods)
end