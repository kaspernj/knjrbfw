class Knj::Http
  attr_reader :cookies
  
  def self.isgdlink(url)
    http = Knj::Http.new("host" => "is.gd")
    http.connect
    resp = http.get("/api.php?longurl=" + url)
    
    return resp["data"]
  end
  
  def initialize(opts = {})
    require "net/http"
    
    @opts = opts
    @cookies = {}
    @mutex = Mutex.new
    
    if opts["useragent"]
      @useragent = opts["useragent"]
    else
      @useragent = "Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.8.0.1; knj:true) Gecko/20060111 Firefox/3.6.0.1"
    end
    
    if block_given?
      begin
        self.check_connected
        yield(self)
      ensure
        self.destroy
      end
    end
  end
  
  #Finished the HTTP-object and unsets all variables to free memory.
  def destroy
    begin
      @http.finish if @http
    rescue IOError
      #ignore - happens when the connection is not started yet.
    end
    
    @http = nil
    @opts = nil
    @cookies = nil
    @mutex = nil
    @useragent = nil
    @lasturl = nil
  end
  
  def opts
    return @opts
  end
  
  def connect
    require "net/https" if @opts["ssl"]
    
    if @opts["port"]
      port = @opts["port"]
    elsif @opts["ssl"]
      port = 443
    else
      port = 80
    end
    
    raise "Invalid host: " + @opts["host"].to_s if !@opts["host"]
    
    @http = Net::HTTP.new(@opts["host"], port)
    @http.set_debug_output($stderr) if @opts["debug"]
    @http.use_ssl = true if @opts["ssl"]
    
    if @opts.key?("validate") and !@opts["validate"]
      @http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end
    
    return self
  end
  
  def check_connected
    self.connect if !@http
  end
  
  def cookiestr
    cookiestr = ""
    @cookies.each do |key, value|
      cookiestr << "; " if cookiestr != ""
      cookiestr << "#{Knj::Php.urlencode(key)}=#{Knj::Php.urlencode(value.to_s)}"
    end
    
    return cookiestr
  end
  
  def cookie_add(cgi_cookie)
    if cgi_cookie.class.name == "CGI::Cookie"
      @cookies[cgi_cookie.name] = cgi_cookie.value
    elsif cgi_cookie.is_a?(Hash)
      @cookies[cgi_cookie["name"]] = cgi_cookie["value"]
    else
      raise "Unknown object: '#{cgi_cookie.class.name}'."
    end
  end
  
  def headers
    tha_headers = {"User-Agent" => @useragent}
    tha_headers["Referer"] = @lasturl if @lasturl
    tha_headers["Cookie"] = cookiestr if cookiestr != ""
    return tha_headers
  end
  
  def setcookie(set_data)
    return nil if !set_data
    
    set_data.each do |cookie_str|
      Knj::Web.parse_set_cookies(cookie_str.to_s).each do |cookie|
        @cookies[cookie["name"]] = cookie["value"]
      end
    end
  end
  
  #Shortcut to spawn a new Http-object and running get on the path.
  def self.get(url)
    data = URI.parse(url)
    
    args = {"host" => data.host}
    args["ssl"] = true if data.scheme == "https"
    args["port"] = data.port if data.port
    
    http = Knj::Http.new(args)
    return http.get(data.path)
  end
  
  def get(addr)
    self.check_connected
    
    @mutex.synchronize do
      resp, data = @http.get(addr, self.headers)
      self.setcookie(resp.response.to_hash["set-cookie"])
      raise Knj::Errors::NotFound, "Could not find that page: '#{addr}'." if resp.is_a?(Net::HTTPNotFound)
      
      #in some cases (like in IronRuby) the data is set like this.
      data = resp.body if !data
      
      return Knj::Http.get(resp["location"]) if resp["location"]
      
      return {
        "response" => resp,
        "data" => data
      }
    end
  end
  
  def head(addr)
    self.check_connected
    
    @mutex.synchronize do
      resp, data = @http.head(addr, self.headers)
      self.setcookie(resp.response.to_hash["set-cookie"])
      
      raise "Could not find that page: '#{addr}'." if resp.is_a?(Net::HTTPNotFound)
      
      #in some cases (like in IronRuby) the data is set like this.
      data = resp.body if !data
      
      return {
        "response" => resp,
        "data" => data
      }
    end
  end
  
  def post(addr, posthash, files = [])
    check_connected
    
    postdata = ""
    posthash.each do |key, value|
      postdata << "&" if postdata != ""
      postdata << "#{Knj::Web.urlenc(key)}=#{Knj::Web.urlenc(value)}"
    end
    
    @mutex.synchronize do
      resp, data = @http.post2(addr, postdata, self.headers)
      self.setcookie(resp.response.to_hash["set-cookie"])
      
      return {
        "response" => resp,
        "data" => data
      }
    end
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
      
      postdata << "--#{boundary}\r\n"
      postdata << "Content-Disposition: form-data; name=\"#{file["pname"]}\"; filename=\"#{file["fname"]}\"\r\n"
      postdata << "Content-Type: text/plain\r\n"
      postdata << "\r\n"
      postdata << File.read(file["path"])
      postdata << "\r\n--#{boundary}--\r\n"
    end
    
    @mutex.synchronize do
      request = Net::HTTP::Post.new(addr)
      request.body = postdata
      request["Content-Type"] = "multipart/form-data, boundary=#{boundary}"
      
      resp, data = @http.request(request)
      self.setcookie(resp.response.to_hash["set-cookie"])
      
      return {
        "response" => resp,
        "data" => data
      }
    end
  end
end