module Knj
	class Web
		include Knj::Php
		include Knj
		
		def cgi; return @cgi; end
		def session; return @session; end
		def data; return @data; end
		
		def initialize(paras = {})
			@paras = paras
			@db = @paras["db"]
			
			if !@paras["tmp"]
				@paras["tmp"] = "/tmp"
			end
			
			if !@paras["id"]
				raise "No ID was given."
			end
			
			if @paras["cgi"]
				@cgi = @paras["cgi"]
			else
				@cgi = CGI.new("html4")
			end
			
			$_CGI = @cgi
			
			@server = {
				"HTTP_HOST" => Apache.request.hostname,
				"HTTP_USER_AGENT" => Apache.request.headers_in["User-Agent"],
				"REMOTE_ADDR" => Apache.request.remote_host(1),
				"REQUEST_URI" => Apache.request.unparsed_uri
			}
			
			@files = {}
			@post = {}
			if @cgi.request_method == "POST"
				@cgi.params.each do |pair|
					do_files = false
					isstring = true
					varname = pair[0]
					stringparse = nil
					
					if pair[1][0].is_a?(Tempfile)
						if varname[0..3] == "file"
							isstring = false
							do_files = true
							
							if pair[1][0].size > 0
								stringparse = {
									"tmp_name" => pair[1][0].path,
									"size" => pair[1][0].size,
									"error" => 0
								}
							end
						else
							stringparse = File.read(pair[1][0].path)
						end
					elsif pair[1][0].is_a?(StringIO)
						if varname[0..3] == "file"
							tmpname = @paras["tmp"] + "/knj_web_upload_#{Time.now.to_f.to_s}_#{rand(1000).to_s.untaint}"
							isstring = false
							do_files = true
							cont = pair[1][0].string
							file_put_contents(tmpname, cont.to_s)
							
							if cont.length > 0
								stringparse = {
									"tmp_name" => tmpname,
									"size" => cont.length,
									"error" => 0
								}
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
								Web.parse_name(@post, varname, stringparse)
							else
								@post[varname] = stringparse
							end
						else
							if isstring
								Web.parse_name(@files, varname, stringparse)
							else
								@files[varname] = stringparse
							end
						end
					end
				end
			end
			
			@get = {}
			if @cgi.query_string
				urldecode(@cgi.query_string.to_s).split("&").each do |value|
					pos = value.index("=")
					
					if pos != nil
						name = value[0..pos-1]
						valuestr = value.slice(pos+1..-1)
						
						Web.parse_name(@get, name, valuestr)
					end
				end
			end
			
			@cookie = {}
			@cgi.cookies.each do |key, value|
				@cookie[key] = value[0]
			end
			
			if @cookie[@paras["id"]]
				@data = $db.single("sessions", "id" => @cookie[@paras["id"]])
				
				if @data
					if @data["user_agent"] != @server["HTTP_USER_AGENT"] or @data["ip"] != @server["REMOTE_ADDR"]
						@data = nil
					else
						@db.update("sessions", {"date_active" => Datestamp.dbstr}, {"id" => @data["id"]})
						session_id = @paras["id"] + "_" + @data["id"]
					end
				end
			end
			
			if !@data or !session_id
				@db.insert("sessions",
					"date_start" => Datestamp.dbstr, "date_active" => Datestamp.dbstr,
					"user_agent" => @server["HTTP_USER_AGENT"],
					"ip" => @server["REMOTE_ADDR"]
				)
				
				@data = @db.single("sessions", "id" => @db.last_id)
				session_id = @paras["id"] + "_" + @data["id"]
				setcookie(@paras["id"], @data["id"])
			end
			
			require "cgi/session"
			require "cgi/session/pstore"
			@session = CGI::Session.new(@session, "database_manager" => CGI::Session::PStore, "session_id" => session_id, "session_path" => @paras["tmp"])
			Kernel.at_exit do
				@session.close
			end
			
			if @paras["globals"]
				self.global_params
			end
		end
		
		def [](key)
			return @session[key]
		end
		
		def []=(key, value)
			return @session[key] = value
		end
		
		def self.parse_name(seton, varname, value)
			if varname and varname.index("[") != nil
				match = varname.match(/\[(.*?)\]/)
				if match
					namepos = varname.index(match[0])
					name = varname.slice(0..namepos - 1)
					
					valuefrom = namepos + match[1].length + 2
					restname = varname.slice(valuefrom..-1)
					
					if !seton[name]
						seton[name] = {}
					end
					
					if restname and restname.index("[") != nil
						if !seton[name][match[1]]
							seton[name][match[1]] = {}
						end
						
						Web.parse_name_second(seton[name][match[1]], restname, value)
					else
						seton[name][match[1]] = value
					end
				else
					seton[varname][match[1]] = value
				end
			else
				seton[varname] = value
			end
		end
		
		def self.parse_name_second(seton, varname, value)
			match = varname.match(/\[(.*?)\]/)
			if match
				namepos = varname.index(match[0])
				name = match[1]
				
				valuefrom = namepos + match[1].length + 2
				restname = varname.slice(valuefrom..-1)
				
				if restname and restname.index("[") != nil
					if !seton[name]
						seton[name] = {}
					end
					
					Web.parse_name_second(seton[name], restname, value)
				else
					seton[name] = value
				end
			else
				seton[varname] = value
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
			@paras = nil
		end
		
		def self.require_eruby(filepath)
			cont = File.read(filepath).untaint
			parse = Erubis.Eruby.new(cont)
			eval(parse.src.to_s)
		end
		
		def self.alert(string)
			html = "<script type=\"text/javascript\">alert(\"#{Knj::Strings.js_safe(string.to_s)}\");</script>"
			print html
		end
		
		def self.redirect(string)
			html = "<script type=\"text/javascript\">location.href=\"#{string}\";</script>"
			print html
			exit
		end
		
		def self.back
			html = "<script type=\"text/javascript\">history.back(-1);</script>"
			print html
			exit
		end
		
		def self.checkval(value, offval)
			if !value
				return offval
			else
				return value
			end
		end
		
		def self.input(paras)
			if paras["value"]
				if paras["value"].is_a?(Array) and !paras["value"][0].is_a?(NilClass)
					value = paras["value"][0][paras["value"][1]]
				elsif paras["value"].is_a?(String) or paras["value"].is_a?(Integer)
					value = paras["value"].to_s
				end
			end
			
			if value.is_a?(NilClass) and paras["value_default"]
				value = paras["value_default"]
			elsif value.is_a?(NilClass)
				value = ""
			end
			
			if value and paras.has_key?("value_func") and paras["value_func"]
				value = Php.call_user_func(paras["value_func"], value)
			end
			
			if !paras["id"]
				paras["id"] = paras["name"]
			end
			
			if !paras["type"] and paras["opts"]
				paras["type"] = "select"
			elsif paras["name"][0..2] == "che"
				paras["type"] = "checkbox"
			elsif !paras["type"]
				paras["type"] = "text"
			end
			
			if paras.has_key?("disabled") and paras["disabled"]
				disabled = "disabled "
			else
				disabled = ""
			end
			
			html = ""
			
			if paras["type"] == "checkbox"
				if value.is_a?(String) and value == "1" or value.to_s == "1"
					checked = " checked"
				else
					checked = ""
				end
				
				if paras.has_key?("value_active")
					checked += " value=\"#{paras["value_active"]}\""
				end
				
				html += "<tr>"
				html += "<td colspan=\"2\" class=\"tdcheck\">"
				html += "<input type=\"checkbox\" class=\"input_checkbox\" id=\"" + paras["id"].html + "\" name=\"" + paras["name"].html + "\"" + checked + " />"
				html += "<label for=\"" + paras["id"].html + "\">" + paras["title"].html + "</label>"
				html += "</td>"
				html += "</tr>"
			else
				html += "<tr>"
				html += "<td class=\"tdt\">"
				html += paras["title"].html
				html += "</td>"
				html += "<td class=\"tdc\">"
				
				if paras["type"] == "textarea"
					if paras.has_key?("height")
						styleadd = " style=\"height: #{paras["height"].html}px;\""
					else
						styleadd = ""
					end
					
					html += "<textarea#{styleadd} class=\"input_textarea\" name=\"" + paras["name"].html + "\" id=\"" + paras["id"].html + "\">" + value + "</textarea>"
				elsif paras["type"] == "fckeditor"
					if !paras["height"]
						paras["height"] = 400
					end
					
					require "/usr/share/fckeditor/fckeditor.rb"
					fck = FCKeditor.new(paras["name"])
					fck.Height = paras["height"].to_i
					fck.Value = value
					html += fck.CreateHtml
				elsif paras["type"] == "select"
					html += "<select name=\"#{paras["name"].html}\" id=\"#{paras["id"].html}\" class=\"input_select\""
					
					if paras["onchange"]
						html += " onchange=\"#{paras["onchange"]}\""
					end
					
					html += ">"
					html += Web.opts(paras["opts"], value, paras["opts_paras"])
					html += "</select>"
				elsif paras["type"] == "imageupload"
					html += "<table class=\"designtable\"><tr><td style=\"width: 100%;\">"
					html += "<input type=\"file\" name=\"#{paras["name"].html}\" class=\"input_file\" />"
					html += "</td><td style=\"padding-left: 5px;\">"
					
					path = paras["path"].gsub("%value%", value).untaint
					if File.exists?(path)
						html += "<img src=\"image.php?picture=#{Php.urlencode(path).html}&smartsize=100&edgesize=25\" alt=\"Image\" />"
						
						if paras["dellink"]
							dellink = paras["dellink"].gsub("%value%", value)
							html += "<div style=\"text-align: center;\">(<a href=\"javascript: if (confirm('#{_("Do you want to delete the image?")}')){location.href='#{dellink}';}\">#{_("delete")}</a>)</div>"
						end
					end
					
					html += "</td></tr></table>"
				else
					html += "<input #{disabled}type=\"#{paras["type"].html}\" class=\"input_#{paras["type"].html}\" id=\"#{paras["id"].html}\" name=\"#{paras["name"].html}\" value=\"#{value.html}\" />"
				end
				
				html += "</tr>"
			end
			
			if paras["descr"]
				html += "<tr><td colspan=\"2\" class=\"tdd\">#{paras["descr"]}</td></tr>"
			end
			
			return html
		end
		
		def self.opts(opthash, curvalue = nil, opts_paras = {})
			if !opthash
				return ""
			end
			
			if curvalue.is_a?(Knj::Db_row)
				curvalue = curvalue.id
			end
			
			html = ""
			if !curvalue
				addsel = " selected=\"selected\""
			end
			
			if opts_paras and opts_paras["add"]
				html += "<option#{addsel} value=\"\">#{_("Add new")}</option>"
			end
			
			if opts_paras and opts_paras["choose"]
				html += "<option#{addsel} value=\"\">#{_("Choose")}</option>"
			end
			
			if opts_paras and opts_paras["none"]
				html += "<option#{addsel} value=\"\">#{_("None")}</option>"
			end
			
			if opthash.class.to_s == "Dictionary"
				opthash.each do |key, value|
					html += "<option"
					
					if curvalue.to_s == key.to_s
						html += " selected=\"selected\""
					end
					
					html += " value=\"#{key.html}\">#{value.html}</option>"
				end
			elsif opthash.is_a?(Hash)
				opthash.each do |key, value|
					html += "<option"
					
					if curvalue.to_s == key.to_s
						html += " selected=\"selected\""
					end
					
					html += " value=\"#{key.html}\">#{value.html}</option>"
				end
			elsif opthash.is_a?(Array)
				opthash.each do |key|
					if opthash[key.to_i] != nil
						html += "<option"
						
						if curvalue.to_i == key.to_i
							html += " selected=\"selected\""
						end
						
						html += " value=\"#{key.to_s}\">#{opthash[key.to_i].to_s}</option>"
					end
				end
			end
			
			return html
		end
		
		def self.rendering_engine
			agent = $_SERVER["HTTP_USER_AGENT"].downcase
			
			if agent.index("webkit") != nil
				return "webkit"
			elsif agent.index("gecko") != nil
				return "gecko"
			elsif agent.index("msie") != nil
				return "msie"
			elsif agent.index("w3c") != nil
				return "bot"
			else
				print "Unknown agent: " + agent
			end
		end
	end
end

def alert(string)
	return Knj.Web.alert(string)
end

def redirect(string)
	return Knj.Web.redirect(string)
end

def jsback(string)
	return Knj.Web.back
end

class String
	def html
		return CGI.escapeHTML(self)
	end
	
	def sql
		return $db.escape(self)
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