module Knj
	class Web
		def cgi; return @cgi; end
		def session; return @session; end
		
		def initialize(paras = {})
			@paras = paras
			@db = @paras["db"]
			
			if (!@paras["id"])
				raise "No ID was given."
			end
			
			if (@paras["cgi"])
				@cgi = @paras["cgi"]
			else
				require "cgi"
				@cgi = CGI.new("html4")
			end
			
			@post = {}
			if (@cgi.request_method == "POST")
				@cgi.params.each do |pair|
					isstring = true
					varname = pair[0]
					
					if pair[1][0].is_a?(Tempfile)
						isstring = false
						stringparse = File.read(pair[1][0].path)
						pair[1][0].unlink
					elsif pair[1][0].is_a?(StringIO)
						stringparse = pair[1][0].string
					else
						stringparse = pair[1][0]
					end
					
					if isstring
						Knj::Web::parse_name(@post, varname, stringparse)
					else
						@post[varname] = stringparse
					end
				end
			end
			
			@get = {}
			if (@cgi.query_string)
				urldecode(@cgi.query_string).split("&").each do |value|
					valuearr = value.split("=")
					
					if valuearr[1]
						valuearr[1] = CGI.unescape(valuearr[1])
					end
					
					Knj::Web::parse_name(@get, valuearr[0], valuearr[1])
				end
			end
			
			@cookie = {}
			@cgi.cookies.each do |key, value|
				@cookie[key] = value[0]
			end
			
			if @cookie[@paras["id"]]
				session_id = @paras["id"] + "_" + @cookie[@paras["id"]]
			else
				@db.insert("sessions", {
					"date_start" => date("Y") + "-" + date("m") + "-" + date("d") + " " + date("H") + ":" + date("i") + ":" + date("s")
				})
				id = @db.last_id
				cookie = CGI::Cookie.new("name" => @paras["id"], "value" => id.to_s)
				@cgi.header("Cookie" => [cookie])
				@cgi.out("cookie" => [cookie]){""}
				session_id = @paras["id"] + "_" + id.to_s
			end
			
			require "cgi/session"
			require "cgi/session/pstore"
			@session = CGI::Session.new(@session, "database_manager" => CGI::Session::PStore, "session_id" => session_id)
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
						
						Knj::Web::parse_name_second(seton[name][match[1]], restname, value)
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
					
					Knj::Web::parse_name_second(seton[name], restname, value)
				else
					seton[name] = value
				end
			else
				seton[varname] = value
			end
		end
		
		def self.global_params
			require "cgi"
			cgi = CGI.new("html4")
			
			$_POST = {}
			if (cgi.request_method == "POST")
				cgi.params.each do |pair|
					if pair[1][0].is_a?(Tempfile)
						$_POST[pair[0]] = File.read(pair[1][0].path)
						pair[1][0].unlink
					else
						$_POST[pair[0]] = pair[1][0]
					end
				end
			end
			
			$_GET = {}
			if (cgi.query_string)
				cgi.query_string.split("&").each do |value|
					valuearr = value.split("=")
					$_GET[valuearr[0]] = CGI.unescape(valuearr[1])
				end
			end
		end
		
		def global_params
			$_POST = @post
			$_GET = @get
			$_COOKIE = @cookie
		end
		
		def destroy
			@cgi = nil
			@post = nil
			@get = nil
			@session = nil
			@paras = nil
		end
		
		def self.require_eruby(filepath)
			require "erubis"
			cont = File.read(filepath)
			parse = Erubis::Eruby.new(cont)
			eval(parse.src.to_s)
		end
		
		def self.alert(string)
			html = "<script type=\"text/javascript\">alert(\"" + string + "\");</script>"
			print html
		end
		
		def self.redirect(string)
			html = "<script type=\"text/javascript\">location.href=\"" + string + "\";</script>"
			print html
			exit
		end
		
		def self.back
			html = "<script type=\"text/javascript\">history.back(-1);</script>"
			print html
			exit
		end
		
		def self.input(paras)
			if (paras["value"])
				if paras["value"].is_a?(Array) and !paras["value"][0].is_a?(NilClass)
					value = paras["value"][0][paras["value"][1]]
				elsif (paras["value"].is_a?(String) or paras["value"].is_a?(Integer))
					value = paras["value"].to_s
				end
			end
			
			if (value.is_a?(NilClass))
				value = ""
			end
			
			if (!paras["id"])
				paras["id"] = paras["name"]
			end
			
			if (!paras["type"])
				paras["type"] = "text"
			end
			
			if (!paras["height"])
				paras["height"] = 400
			end
			
			html = ""
			
			if (paras["type"] == "checkbox")
				if (value.is_a(String) and value == "1")
					checked = " checked"
				else
					checked = ""
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
				
				if (paras["type"] == "textarea")
					html += "<textarea class=\"input_textarea\" name=\"" + paras["name"].html + "\" id=\"" + paras["id"].html + "\">" + value + "</textarea>"
				elsif (paras["type"] == "fckeditor")
					require "/usr/share/fckeditor/fckeditor.rb"
					fck = FCKeditor.new(paras["name"])
					fck.Height = paras["height"].to_i
					fck.Value = value
					html += fck.CreateHtml
				elsif paras["type"] == "select"
					html += "<select name=\"#{paras["name"].html}\" id=\"#{paras["id"].html}\" class=\"input_select\">"
					html += Knj::Web::opts(paras["opts"], value)
					html += "</select>"
				else
					html += "<input type=\"" + paras["type"].html + "\" class=\"input_" + paras["type"].html + "\" id=\"" + paras["id"].html + "\" name=\"" + paras["name"].html + "\" value=\"" + value.html + "\" />"
				end
				
				html += "</tr>"
			end
			
			return html
		end
		
		def self.opts(opthash, curvalue = nil)
			if !opthash
				return ""
			end
			
			html = ""
			
			opthash.each do |key, value|
				html += "<option"
				
				if curvalue == key
					html += " selected=\"selected\""
				end
				
				html += " value=\"#{key.html}\">#{value.html}</option>"
			end
			
			return html
		end
	end
end

def alert(string)
	return Knj::Web::alert(string)
end

def redirect(string)
	return Knj::Web::redirect(string)
end

def jsback(string)
	return Knj::Web::back
end

class String
	def html
		require("cgi")
		return CGI.escapeHTML(self)
	end
	
	def sql
		return $db.escape(self)
	end
end