class KnjHTTPClient
	def initialize(opts)
		@opts = opts
		@cookies = {}
		@useragent = "Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.8.0.1) Gecko/20060111 Firefox/1.5.0.1"
	end
	
	def opts
		return @opts
	end
	
	def connect
		require "net/http"
		
		if (@opts["ssl"])
			require "net/https"
		end
		
		if (@opts["port"])
			port = @opts["port"]
		elsif (@opts["ssl"])
			port = 443
		else
			port = 80
		end
		
		@http = Net::HTTP.new(@opts["host"], port)
		
		if (@opts["ssl"])
			@http.use_ssl = true
		end
	end
	
	def cookiestr
		cookiestr = ""
		@cookies.each do |key, value|
			if (cookiestr != "")
				cookiestr += "; "
			end
			
			cookiestr += key + "=" + value
		end
		
		return cookiestr
	end
	
	def headers
		tha_headers = {
			"User-Agent" => @useragent,
		}
		
		if (@lasturl)
			tha_headers["Referer"] = @lasturl
		end
		
		if (cookiestr != "")
			tha_headers["Cookie"] = self.cookiestr
		end
		
		return tha_headers
	end
	
	def setcookie(set_data)
		if (set_data and set_data.length > 0)
			set_data.split(", ").each do |cookiestr|
				cookiedata = cookiestr.split(";")[0].split("=")
				@cookies[cookiedata[0]] = cookiedata[1]
			end
		end
	end
	
	def get(addr)
		resp, data = @http.get2(addr, self.headers)
		self.setcookie(resp.response["set-cookie"])
		
		return {
			"response" => resp,
			"data" => data
		}
	end
	
	def post(addr, posthash)
		require "cgi"
		
		postdata = ""
		posthash.each do |key, value|
			if (postdata != "")
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
end