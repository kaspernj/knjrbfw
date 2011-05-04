class Knj::Web
	attr_reader :session, :cgi, :data
	
	def initialize(args = {})
		@args = Knj::ArrayExt.hash_sym(args)
		@db = @args[:db] if @args[:db] 
		@args[:tmp] = "/tmp" if !@args[:tmp]
		
		raise "No ID was given." if !@args[:id]
		raise "No DB was given." if !@args[:db]
		
		if @args[:cgi]
			@cgi = @args[:cgi]
		elsif $_CGI
			@cgi = $_CGI
		else
			if ENV["HTTP_HOST"] or $knj_eruby or Knj::Php.class_exists("Apache")
				@cgi = CGI.new
			end
		end
		
		$_CGI = @cgi if !$_CGI
		self.read_cgi
		
		if $_FCGI
			KnjEruby.connect("exit") do
				@session.close
				
				@post = nil
				@get = nil
				@server = nil
				@cookie = nil
				
				$_POST = nil
				$_GET = nil
				$_SERVER = nil
				$_COOKIE = nil
			end
		else
			Kernel.at_exit do
				@session.close
				
				@post = nil
				@get = nil
				@server = nil
				@cookie = nil
				
				$_POST = nil
				$_GET = nil
				$_SERVER = nil
				$_COOKIE = nil
			end
		end
	end
	
	def read_cgi(args = {})
		args.each do |key, value|
			if key == :cgi
				@cgi = value
			else
				raise "No such key: #{key.to_s}"
			end
		end
		
		if $_FCGI_COUNT and $_FCGI and $_CGI
			@server = {}
			$_CGI.env_table.each do |key, value|
				@server[key] = value
			end
		elsif $_CGI and ENV["HTTP_HOST"] and ENV["REMOTE_ADDR"]
			@server = {}
			ENV.each do |key, value|
				@server[key] = value
			end
		elsif Knj::Php.class_exists("Apache")
			@server = {
				"HTTP_HOST" => Apache.request.hostname,
				"HTTP_USER_AGENT" => Apache.request.headers_in["User-Agent"],
				"REMOTE_ADDR" => Apache.request.remote_host(1),
				"REQUEST_URI" => Apache.request.unparsed_uri
			}
		else
			@server = {}
		end
		
		@files = {}
		@post = {}
		if @cgi and @cgi.request_method == "POST"
			@cgi.params.each do |pair|
				do_files = false
				isstring = true
				varname = pair[0]
				stringparse = nil
				
				if pair[1][0].class.name == "Tempfile"
					if varname[0..3] == "file"
						isstring = false
						do_files = true
						
						if pair[1][0].size > 0
							stringparse = {
								"name" => pair[1][0].original_filename,
								"tmp_name" => pair[1][0].path,
								"size" => pair[1][0].size,
								"error" => 0
							}
							
							stringparse["name"] = pair[1][0].original_filename if pair[1][0].respond_to?("original_filename")
						end
					else
						stringparse = File.read(pair[1][0].path)
					end
				elsif pair[1][0].is_a?(StringIO)
					if varname[0..3] == "file"
						tmpname = @args[:tmp] + "/knj_web_upload_#{Time.now.to_f.to_s}_#{rand(1000).to_s.untaint}"
						isstring = false
						do_files = true
						cont = pair[1][0].string
						Knj::Php.file_put_contents(tmpname, cont.to_s)
						
						if cont.length > 0
							stringparse = {
								"tmp_name" => tmpname,
								"size" => cont.length,
								"error" => 0
							}
							
							stringparse["name"] = pair[1][0].original_filename if pair[1][0].respond_to?("original_filename")
						end
					else
						stringparse = pair[1][0].string
					end
				else
					stringparse = pair[1][0]
				end
				
				if stringparse
					if !do_files
						if isstring
							Knj::Web.parse_name(@post, varname, stringparse)
						else
							@post[varname] = stringparse
						end
					else
						if isstring
							Knj::Web.parse_name(@files, varname, stringparse)
						else
							@files[varname] = stringparse
						end
					end
				end
			end
		end
		
		
		if @cgi and @cgi.query_string
			@get = Knj::Web.parse_urlquery(@cgi.query_string)
		else
			@get = {}
		end
		
		@cookie = {}
		if @cgi
			@cgi.cookies.each do |key, value|
				@cookie[key] = value[0]
			end
		end
		
		self.global_params if @args[:globals]
		
		if @cookie[@args[:id]] and (sdata = @args[:db].single(:sessions, :id => @cookie[@args[:id]]))
			@data = Knj::ArrayExt.hash_sym(sdata)
			
			if @data
				if @data[:user_agent] != @server["HTTP_USER_AGENT"] or @data[:ip] != @server["REMOTE_ADDR"]
					@data = nil
				else
					@db.update(:sessions, {"last_url" => @server["REQUEST_URI"].to_s, "date_active" => Datestamp.dbstr}, {"id" => @data[:id]})
					session_id = @args[:id] + "_" + @data[:id]
				end
			end
		end
		
		if !@data or !session_id
			@db.insert(:sessions,
				:date_start => Knj::Datet.new.dbstr,
				:date_active => Knj::Datet.new.dbstr,
				:user_agent => @server["HTTP_USER_AGENT"],
				:ip => @server["REMOTE_ADDR"],
				:last_url => @server["REQUEST_URI"].to_s
			)
			
			@data = Knj::ArrayExt.hash_sym(@db.single(:sessions, :id => @db.last_id))
			session_id = @args[:id] + "_" + @data[:id]
			Knj::Php.setcookie(@args[:id], @data[:id])
		end
		
		require "cgi/session"
		require "cgi/session/pstore"
		@session = CGI::Session.new(@session, "database_manager" => CGI::Session::PStore, "session_id" => session_id, "session_path" => @args[:tmp])
	end
	
	def [](key)
		return @session[key.to_sym]
	end
	
	def []=(key, value)
		return @session[key.to_sym] = value
	end
	
	def self.parse_urlquery(querystr, args = {})
		get = {}
		Knj::Php.urldecode(querystr).split("&").each do |value|
			pos = value.index("=")
			
			if pos != nil
				name = value[0..pos-1]
				name = name.to_sym if args[:syms]
				valuestr = value.slice(pos+1..-1)
				Knj::Web.parse_name(get, name, valuestr, args)
			end
		end
		
		return get
	end
	
	def self.parse_secname(seton, secname, args)
		secname_empty = false
		if secname.length <= 0
			secname_empty = true
			try = 0
			
			loop do
				if !seton.has_key?(try)
					break
				else
					try += 1
				end
			end
			
			secname = try
		else
			secname = secname.to_i if Knj::Php.is_numeric(secname)
		end
		
		secname = secname.to_sym if args[:syms] and secname.is_a?(String)
		
		return [secname, secname_empty]
	end
	
	def self.parse_name(seton, varname, value, args = {})
		if value.respond_to?(:filename) and value.filename
			realvalue = value
		else
			realvalue = value.to_s
		end
		
		if varname and varname.index("[") != nil
			if match = varname.match(/\[(.*?)\]/)
				namepos = varname.index(match[0])
				name = varname.slice(0..namepos - 1)
				name = name.to_sym if args[:syms]
				seton[name] = {} if !seton.has_key?(name)
				
				secname, secname_empty = Knj::Web.parse_secname(seton[name], match[1], args)
				
				valuefrom = namepos + secname.to_s.length + 2
				restname = varname.slice(valuefrom..-1)
				
				if restname and restname.index("[") != nil
					seton[name][secname] = {} if !seton[name].has_key?(secname)
					Knj::Web.parse_name_second(seton[name][secname], restname, value, args)
				else
					seton[name][secname] = realvalue
				end
			else
				seton[varname][match[1]] = realvalue
			end
		else
			seton[varname] = realvalue
		end
	end
	
	def self.parse_name_second(seton, varname, value, args = {})
		if value.respond_to?(:filename) and value.filename
			realvalue = value
		else
			realvalue = value.to_s
		end
		
		match = varname.match(/^\[(.*?)\]/)
		if match
			namepos = varname.index(match[0])
			name = match[1]
			secname, secname_empty = Knj::Web.parse_secname(seton, match[1], args)
			
			valuefrom = namepos + match[1].length + 2
			restname = varname.slice(valuefrom..-1)
			
			if restname and restname.index("[") != nil
				seton[secname] = {} if !seton.has_key?(secname)
				Knj::Web.parse_name_second(seton[secname], restname, value, args)
			else
				seton[secname] = realvalue
			end
		else
			seton[varname] = realvalue
		end
	end
	
	def global_params
		$_POST = @post
		$_GET = @get
		$_COOKIE = @cookie
		$_FILES = @files
		$_SERVER = @server
	end
	
	def destroy
		@cgi = nil
		@post = nil
		@get = nil
		@session = nil
		@args = nil
	end
	
	def self.require_eruby(filepath)
		cont = File.read(filepath).untaint
		parse = Erubis.Eruby.new(cont)
		eval(parse.src.to_s)
	end
	
	def self.alert(string)
		@alert_sent = true
		html = "<script type=\"text/javascript\">alert(\"#{Knj::Strings.js_safe(string.to_s)}\");</script>"
		print html
	end
	
	def self.redirect(string, args = {})
		do_js = true
		
		#Header way
		if !@alert_sent
			if args[:perm]
				Knj::Php.header("Status: 301 Moved Permanently")
			else
				Knj::Php.header("Status: 303 See Other")
			end
			
			Knj::Php.header("Location: #{string}")
		end
		
		print "<script type=\"text/javascript\">location.href=\"#{string}\";</script>" if do_js
		exit
	end
	
	def self.back
		print "<script type=\"text/javascript\">history.go(-1);</script>"
		exit
	end
	
	def self.checkval(value, val1, val2 = nil)
		if val2 != nil
			if !value or value == ""
				return val2
			else
				return val1
			end
		else
			if !value or value == ""
				return val1
			else
				return value
			end
		end
	end
	
	def self.inputs(arr)
		html = ""
		arr.each do |args|
			html += self.input(args)
		end
		
		return html
	end
	
	def self.input(args)
		Knj::ArrayExt.hash_sym(args)
		
		if args.has_key?(:value)
			if args[:value].is_a?(Array)
				if !args[:value][0].is_a?(NilClass)
					value = args[:value][0][args[:value][1]]
				end
			elsif args[:value].is_a?(String) or args[:value].is_a?(Integer)
				value = args[:value].to_s
			else
				value = args[:value]
			end
		end
		
		args[:value_default] = args[:default] if args[:default]
		
		if value.is_a?(NilClass) and args[:value_default]
			value = args[:value_default]
		elsif value.is_a?(NilClass)
			value = ""
		end
		
		if value and args.has_key?(:value_func) and args[:value_func]
			cback = args[:value_func]
			
			if cback.is_a?(Method)
				value = cback.call(value)
			elsif cback.is_a?(Array)
				value = Knj::Php.call_user_func(args[:value_func], value)
			else
				raise "Unknown class: #{cback.class.name}."
			end
		end
		
		value = args[:values] if args[:values]
		args[:id] = args[:name] if !args[:id]
		
		if !args[:type]
			if args[:opts]
				args[:type] = :select
			elsif args[:name] and args[:name].to_s[0..2] == "che"
				args[:type] = :checkbox
			elsif args[:name] and args[:name].to_s[0..3] == "file"
				args[:type] = :file
			else
				args[:type] = :text
			end
		else
			args[:type] = args[:type].to_sym
		end
		
		if args.has_key?(:disabled) and args[:disabled]
			disabled = "disabled "
		else
			disabled = ""
		end
		
		raise "No name given to the Web::input()-method." if !args[:name] and args[:type] != :info and args[:type] != :textshow
		
		checked = ""
		checked += " value=\"#{args[:value_active]}\"" if args.has_key?(:value_active)
		checked += " checked" if value.is_a?(String) and value == "1" or value.to_s == "1"
		checked += " checked" if value.is_a?(TrueClass)
		
		html = ""
		
		if args[:type] == :checkbox
			html += "<tr>"
			html += "<td colspan=\"2\" class=\"tdcheck\">"
			html += "<input type=\"checkbox\" class=\"input_checkbox\" id=\"#{args[:id].html}\" name=\"#{args[:name].html}\"#{checked} />"
			html += "<label for=\"#{args[:id].html}\">#{args[:title].html}</label>"
			html += "</td>"
			html += "</tr>"
		else
			html += "<tr>"
			html += "<td class=\"tdt\">"
			html += args[:title].html
			html += "</td>"
			html += "<td class=\"tdc\">"
			
			if args[:type] == :textarea
				if args.has_key?(:height)
					styleadd = " style=\"height: #{args[:height].html}px;\""
				else
					styleadd = ""
				end
				
				html += "<textarea#{styleadd} class=\"input_textarea\" name=\"#{args[:name].html}\" id=\"#{args[:id].html}\">#{value}</textarea>"
				html += "</td>"
			elsif args[:type] == :fckeditor
				args[:height] = 400 if !args[:height]
				
				require "/usr/share/fckeditor/fckeditor.rb"
				fck = FCKeditor.new(args[:name])
				fck.Height = args[:height].to_i
				fck.Value = value
				html += fck.CreateHtml
				
				html += "</td>"
			elsif args[:type] == :select
				html += "<select name=\"#{args[:name].html}\" id=\"#{args[:id].html}\" class=\"input_select\""
				html += " onchange=\"#{args[:onchange]}\"" if args[:onchange]
				html += " multiple" if args[:multiple]
				html += " size=\"#{args[:size].to_s}\"" if args[:size]
				html += ">"
				html += Knj::Web.opts(args[:opts], value, args[:opts_args])
				html += "</select>"
				html += "</td>"
			elsif args[:type] == :imageupload
				html += "<table class=\"designtable\"><tr><td style=\"width: 100%;\">"
				html += "<input type=\"file\" name=\"#{args[:name].html}\" class=\"input_file\" />"
				html += "</td><td style=\"padding-left: 5px;\">"
				
				path = args[:path].gsub("%value%", value.to_s).untaint
				if File.exists?(path)
					html += "<img src=\"image.php?picture=#{Knj::Php.urlencode(path).html}&smartsize=100&edgesize=25\" alt=\"Image\" />"
					
					if args[:dellink]
						dellink = args[:dellink].gsub("%value%", value.to_s)
						html += "<div style=\"text-align: center;\">(<a href=\"javascript: if (confirm('#{_("Do you want to delete the image?")}')){location.href='#{dellink}';}\">#{_("delete")}</a>)</div>"
					end
				end
				
				html += "</td></tr></table>"
				html += "</td>"
			elsif args[:type] == :file
				html += "<input type=\"#{args[:type].to_s}\" class=\"input_#{args[:type].to_s}\" name=\"#{args[:name].html}\" /></td>"
			elsif args[:type] == :textshow or args[:type] == :info
				html += "#{value}</td>"
			else
				html += "<input #{disabled}type=\"#{args[:type].to_s.html}\" class=\"input_#{args[:type].html}\" id=\"#{args[:id].html}\" name=\"#{args[:name].html}\" value=\"#{value.html}\" /></td>"
				html += "</td>"
			end
			
			html += "</tr>"
		end
		
		html += "<tr><td colspan=\"2\" class=\"tdd\">#{args[:descr]}</td></tr>" if args[:descr]
		return html
	end
	
	def self.opts(opthash, curvalue = nil, opts_args = {})
		opts_args = {} if !opts_args
		opts_args.each do |key, value|
			if !key.is_a?(Symbol)
				opts_args[key.to_sym] = value
				opts_args.delete(key)
			end
		end
		
		return "" if !opthash
		curvalue = curvalue.id if curvalue.is_a?(Knj::Db_row)
		
		html = ""
		addsel = " selected=\"selected\"" if !curvalue
		
		html += "<option#{addsel} value=\"\">#{_("Add new")}</option>" if opts_args and (opts_args[:add] or opts_args[:addnew])
		html += "<option#{addsel} value=\"\">#{_("Choose")}</option>" if opts_args and opts_args[:choose]
		html += "<option#{addsel} value=\"\">#{_("None")}</option>" if opts_args and opts_args[:none]
		
		if opthash.is_a?(Hash) or opthash.class.to_s == "Dictionary"
			opthash.each do |key, value|
				html += "<option"
				
				if curvalue.is_a?(Array) and curvalue.index(key) != nil
					html += " selected=\"selected\""
				elsif curvalue.to_s == key.to_s
					html += " selected=\"selected\""
				end
				
				html += " value=\"#{key.html}\">#{value.html}</option>"
			end
		elsif opthash.is_a?(Array)
			opthash.each do |key|
				if opthash[key.to_i] != nil
					html += "<option"
					html += " selected=\"selected\"" if curvalue.to_i == key.to_i
					html += " value=\"#{key.to_s}\">#{opthash[key.to_i].to_s}</option>"
				end
			end
		end
		
		return html
	end
	
	def self.rendering_engine
		begin
			servervar = _server
		rescue Exception
			servervar = $_SERVER
		end
		
		if !servervar
			raise "Could not figure out meta data."
		end
		
		agent = servervar["HTTP_USER_AGENT"].to_s.downcase
		
		if agent.index("webkit") != nil
			return "webkit"
		elsif agent.index("gecko") != nil
			return "gecko"
		elsif agent.index("msie") != nil
			return "msie"
		elsif agent.index("w3c") != nil or agent.index("baiduspider") != nil or agent.index("googlebot") != nil
			return "bot"
		else
			#print "Unknown agent: #{agent}"
			return false
		end
	end
	
	def self.os
		begin
			servervar = _server
		rescue Exception
			servervar = $_SERVER
		end
		
		if !servervar
			raise "Could not figure out meta data."
		end
		
		agent = servervar["HTTP_USER_AGENT"].to_s.downcase
		
		if agent.index("(windows;") != nil or agent.index("windows nt") != nil
			return {
				"os" => "win",
				"title" => "Windows"
			}
		elsif agent.index("linux") != nil
			return {
				"os" => "linux",
				"title" => "Linux"
			}
		end
		
		raise "Unknown OS: #{agent}"
	end
	
	def self.browser(servervar = nil)
		if !servervar
			begin
				servervar = _server
			rescue Exception
				servervar = $_SERVER
			end
		end
		
		raise "Could not figure out meta data." if !servervar
		agent = servervar["HTTP_USER_AGENT"].to_s.downcase
		
		if match = agent.index("knj:true") != nil
			browser = "bot"
			title = "Bot"
			version = "KnjHttp"
		elsif match = agent.match(/chrome\/(\d+\.\d+)/)
			browser = "chrome"
			title = "Google Chrome"
			version = match[1]
		elsif match = agent.match(/firefox\/(\d+\.\d+)/)
			browser = "firefox"
			title = "Mozilla Firefox"
			version = match[1]
		elsif match = agent.match(/msie\s*(\d+\.\d+)/)
			browser = "ie"
			title = "Microsoft Internet Explorer"
			version = match[1]
		elsif match = agent.match(/opera\/([\d+\.]+)/)
			browser = "opera"
			title = "Opera"
			version = match[1]
		elsif match = agent.match(/wget\/([\d+\.]+)/)
			browser = "bot"
			title = "Bot"
			version = "Wget #{match[1]}"
		elsif agent.index("baiduspider") != nil
			browser = "bot"
			title = "Bot"
			version = "Baiduspider"
		elsif agent.index("googlebot") != nil
			browser = "bot"
			title = "Bot"
			version = "Googlebot"
		elsif agent.index("gidbot") != nil
			browser = "bot"
			title = "Bot"
			version "GIDBot"
		elsif match = agent.match(/safari\/(\d+)/)
			browser = "safari"
			title = "Safari"
			version = match[1]
		elsif agent.index("iPad") != nil
			browser = "safari"
			title = "Safari (iPad)"
			version = "ipad"
		elsif agent.index("bingbot") != nil
			browser = "bot"
			title = "Bot"
			version = "Bingbot"
		elsif agent.index("yahoo! slurp") != nil
			browser = "bot"
			title = "Bot"
			version = "Yahoo! Slurp"
		elsif agent.index("hostharvest") != nil
			browser = "bot"
			title = "Bot"
			version = "HostHarvest"
		elsif agent.index("exabot") != nil
			browser = "bot"
			title = "Bot"
			version = "Exabot"
		elsif agent.index("dotbot") != nil
			browser = "bot"
			title = "Bot"
			version = "DotBot"
		elsif agent.index("msnbot") != nil
			browser = "bot"
			title = "Bot"
			version = "MSN bot"
		elsif agent.index("yandexbot") != nil
			browser = "bot"
			title = "Bot"
			version = "Yandex Bot"
		elsif agent.index("mj12bot") != nil
			browser = "bot"
			title = "Bot"
			version "Majestic12 Bot"
		elsif agent.index("facebookexternalhit") != nil
			browser = "bot"
			title = "Bot"
			version = "Facebook Externalhit"
		elsif agent.index("SiteBot") != nil
			browser = "bot"
			title = "Bot"
			version = "SiteBot"
		elsif agent.match(/java\/([\d\.]+)/)
			browser = "bot"
			title = "Java"
			version = match[1]
		else
			browser = "unknown"
			title = "(unknown browser)"
			version = "(unknown version)"
		end
		
		return {
			"browser" => browser,
			"title" => title,
			"version" => version
		}
	end
	
	def self.locale(args = {})
		begin
			servervar = _server
		rescue Exception
			servervar = $_SERVER
		end
		
		if !servervar
			raise "Could not figure out meta data."
		end
		
		ret = {
			:recommended => [],
			:browser => []
		}
		
		alangs = servervar["HTTP_ACCEPT_LANGUAGE"].to_s
		if alangs.length > 0
			alangs.split(/\s*,\s*/).each do |alang|
				if qmatch = alang.match(/;\s*q=([\d\.]+)/)
					alang.gsub!(/;\s*q=([\d\.]+)/, "")
					q = qmatch[1].to_f
				else
					q = 1.0
				end
				
				if match = alang.match(/^([A-z]+)-([A-z]+)$/)
					locale = match[1]
					sublocale = match[2]
				else
					locale = alang
					sublocale = false
				end
				
				ret[:browser] << {
					:locale => locale,
					:sublocale => sublocale,
					:q => q
				}
			end
		end
		
		if args[:supported] and ret[:browser]
			ret[:browser].each do |locale|
				args[:supported].each do |supported_locale|
					if match = supported_locale.match(/^([A-z]+)_([A-z]+)$/)
						if match[1] == locale[:locale]
							if !locale[:sublocale]
								ret[:recommended] << supported_locale if ret[:recommended].index(supported_locale) == nil
							elsif locale[:sublocale] == match[1]
								ret[:recommended] << supported_locale if ret[:recommended].index(supported_locale) == nil
							end
						end
					end
				end
			end
		end
		
		if args[:default]
			ret[:recommended] << args[:default] if ret[:recommended].index(args[:default]) == nil
		end
		
		return ret
	end
	
	def self.hiddens(hidden_arr)
		html = ""
		
		hidden_arr.each do |hidden_hash|
			html += "<input type=\"hidden\" name=\"#{hidden_hash[:name].to_s.html}\" value=\"#{hidden_hash[:value].to_s.html}\" />"
		end
		
		return html
	end
end

def alert(string)
	return Knj::Web.alert(string)
end

def redirect(string)
	return Knj::Web.redirect(string)
end

def jsback(string)
	return Knj::Web.back
end

class String
	def html
		return self.to_s.gsub(/&/, "&amp;").gsub(/\"/, "&quot;").gsub(/>/, "&gt;").gsub(/</, "&lt;")
	end
	
	def sql
		if Thread.current.class.name == "Knj::Thread" and Thread.current[:knjappserver] and Thread.current[:knjappserver][:db]
			return Thread.current[:knjappserver][:db].escape(self)
		elsif $db
			return $db.escape(self)
		end
		
		raise "Could not figure out where to find db object."
	end
end

class Symbol
	def html
		return self.to_s.html
	end
	
	def sql
		return self.to_s.sql
	end
end

class Fixnum
	def sql
		return self.to_s.sql
	end
	
	def html
		return self.to_s.html
	end
end