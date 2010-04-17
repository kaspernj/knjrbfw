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
					if pair[1][0].is_a?(Tempfile)
						@post[pair[0]] = File.read(pair[1][0].path)
						pair[1][0].unlink
					else
						@post[pair[0]] = pair[1][0]
					end
				end
			end
			
			@get = {}
			if (@cgi.query_string)
				@cgi.query_string.split("&").each do |value|
					valuearr = value.split("=")
					@get[valuearr[0]] = valuearr[1]
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
					$_GET[valuearr[0]] = valuearr[1]
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
		
		def self.input(paras)
			if (paras["value"])
				if (paras["value"].is_a?(Array) and paras["value"][0].class.to_s != "NilClass")
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
				if (value.class.to_s == "String" and value == "1")
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
				else
					html += "<input type=\"" + paras["type"].html + "\" class=\"input_" + paras["type"].html + "\" id=\"" + paras["id"].html + "\" name=\"" + paras["name"].html + "\" value=\"" + value.html + "\" />"
				end
				
				html += "</tr>"
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
	html = "<script type=\"text/javascript\">history.back(-1);</script>"
	print html
	exit
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