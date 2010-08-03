module Knj
	class Http
		attr_reader :cookies
		
		def self.isgdlink(url)
			http = Knj::Http.new(
				"host" => "is.gd"
			)
			http.connect
			resp = http.get("api.php?longurl=" + url)
			
			return resp["data"]
		end
		
		def initialize(opts = {})
			@opts = opts
			@cookies = {}
			@useragent = "Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.8.0.1) Gecko/20060111 Firefox/1.5.0.1"
		end
		
		def opts
			return @opts
		end
		
		def connect
			if @opts["ssl"]
				require "net/https"
			end
			
			if @opts["port"]
				port = @opts["port"]
			elsif @opts["ssl"]
				port = 443
			else
				port = 80
			end
			
			@http = Net::HTTP.new(@opts["host"], port)
			
			if @opts["ssl"]
				@http.use_ssl = true
			end
		end
		
		def check_connected
			if !@http
				self.connect
			end
		end
		
		def cookiestr
			cookiestr = ""
			@cookies.each do |key, value|
				if cookiestr != ""
					cookiestr += "; "
				end
				
				cookiestr += key + "=" + value
			end
			
			return cookiestr
		end
		
		def headers
			tha_headers = {"User-Agent" => @useragent}
			
			if @lasturl
				tha_headers["Referer"] = @lasturl
			end
			
			if cookiestr != ""
				tha_headers["Cookie"] = self.cookiestr
			end
			
			return tha_headers
		end
		
		def setcookie(set_data)
			if set_data and set_data.length > 0
				set_data.split(", ").each do |cookiestr|
					cookiedata = cookiestr.split(";")[0].split("=")
					@cookies[cookiedata[0]] = cookiedata[1]
				end
			end
		end
		
		def get(addr)
			check_connected
			
			resp, data = @http.get(addr, self.headers)
			self.setcookie(resp.response["set-cookie"])
			
			return {
				"response" => resp,
				"data" => data
			}
		end
		
		def post(addr, posthash, files = [])
			check_connected
			
			postdata = ""
			posthash.each do |key, value|
				if postdata != ""
					postdata += "&"
				end
				
				postdata += CGI.escape(key) + "=" + CGI.escape(value)
			end
			
			resp, data = @http.post2(addr, postdata, self.headers)
			self.setcookie(resp.response["set-cookie"])
			
			return {
				"response" => resp,
				"data" => data
			}
		end
		
		def post_file(addr, files)
			check_connected
			
			boundary = "HJyakstdASDTuyatdtasdtASDTASDasduyAS"
			postdata = ""
			
			files.each do |file|
				if file.is_a?(String)
					file = {
						"pname" => "fileupload",
						"fname" => File.basename(file),
						"path" => file
					}
				end
				
				postdata += "--#{boundary}\r\n"
				postdata += "Content-Disposition: form-data; name=\"#{file["pname"]}\"; filename=\"#{file["fname"]}\"\r\n"
				postdata += "Content-Type: text/plain\r\n"
				postdata += "\r\n"
				postdata += File.read(file["path"])
				postdata += "\r\n--#{boundary}--\r\n"
			end
			
			request = Net::HTTP::Post.new(addr)
			request.body = postdata
			request["Content-Type"] = "multipart/form-data, boundary=#{boundary}"
			
			resp, data = @http.request(request)
			self.setcookie(resp.response["set-cookie"])
			
			return {
				"response" => resp,
				"data" => data
			}
		end
	end
end