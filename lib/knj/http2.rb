class Knj::Http2
  attr_reader :cookies
  
  def initialize(args)
    require "knj/web"
    
    @args = args
    @cookies = {}
    @debug = @args[:debug]
    
    if !@args[:port]
      if @args[:ssl]
        @args[:port] = 443
      else
        @args[:port] = 80
      end
    end
    
    if @args[:nl]
      @nl = @args[:nl]
    else
      @nl = "\r\n"
    end
    
    if @args[:user_agent]
      @uagent = @args[:user_agent]
    else
      @uagent = "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; SV1)"
    end
    
    raise "No host was given." if !@args[:host]
    self.reconnect
  end
  
  def reconnect
    @sock_plain = TCPSocket.new(@args[:host], @args[:port])
    
    if @args[:ssl]
      require "openssl"
      
      ssl_context = OpenSSL::SSL::SSLContext.new
      #ssl_context.verify_mode = OpenSSL::SSL::VERIFY_PEER
      
      @sock_ssl = OpenSSL::SSL::SSLSocket.new(@sock_plain, ssl_context)
      @sock_ssl.sync_close = true
      @sock_ssl.connect
      
      @sock = @sock_ssl
    else
      @sock = @sock_plain
    end
  end
  
  def get(addr)
    header_str = "GET /#{addr} HTTP/1.1#{@nl}"
    header_str += self.header_str(
      "Host" => @args[:host],
      "Connection" => "Keep-Alive",
      "User-Agent" => @uagent
    )
    header_str += "#{@nl}"
    
    self.write(header_str)
    return self.read_response
  end
  
  #Tries to write a string to the socket. If it fails it reconnects and tries again.
  def write(str)
    begin
      raise Errno::EPIPE, "The socket is closed." if !@sock or @sock.closed?
      @sock.puts(str)
    rescue Errno::EPIPE #this can also be thrown by puts.
      self.reconnect
      @sock.puts(str)
    end
  end
  
  def post(addr, pdata = {})
    praw = ""
    pdata.each do |key, val|
      praw += "&" if praw != ""
      praw += "#{Knj::Web.urlenc(key)}=#{Knj::Web.urlenc(val)}"
    end
    
    header_str = "POST /#{addr} HTTP/1.1#{@nl}"
    header_str += self.header_str(
      "Host" => @args[:host],
      "Connection" => "Keep-Alive",
      "User-Agent" => @uagent,
      "Content-Length" => praw.length
    )
    header_str += "#{@nl}"
    header_str += praw
    
    self.write(header_str)
    return self.read_response
  end
  
  def header_str(headers_hash)
    if @cookies.length > 0
      cstr = ""
      
      first = true
      @cookies.each do |cookie_name, cookie_data|
        cstr += "; " if !first
        first = false if first
        
        cstr += "#{Knj::Web.urlenc(cookie_data["name"])}=#{Knj::Web.urlenc(cookie_data["value"])}"
      end
      
      headers_hash["Cookie"] = cstr
    end
    
    headers_str = ""
    
    headers_hash.each do |key, val|
      headers_str += "#{key}: #{val}#{@nl}"
    end
    
    return headers_str
  end
  
  def read_response
    @mode = "headers"
    @resp = Knj::Http2::Response.new
    
    loop do
      begin
        line = @sock.gets
      rescue Errno::ECONNRESET
        line = ""
        @sock = nil
      end
      
      break if line.to_s == ""
      
      if @mode == "headers" and line == @nl
        break if @resp.header("content-length") == "0"
        @mode = "body"
        next
      end
      
      if @mode == "headers"
        self.parse_header(line)
      elsif @mode == "body"
        stat = self.parse_body(line)
        break if stat == "break"
        next if stat == "next"
      end
    end
    
    #Release variables.
    resp = @resp
    @resp = nil
    @mode = nil
    
    if resp.args[:code] == "302" and resp.header?("location")
      uri = URI.parse(resp.header("location"))
      
      args = {:host => uri.host}
      args[:ssl] = true if uri.scheme == "https"
      args[:port] = uri.port if uri.port
      
      if !args[:host] or args[:host] == @args[:host]
        return self.get(resp.header("location"))
      else
        http = Knj::Http2.new(args)
        return http.get(uri.path)
      end
    else
      return resp
    end
  end
  
  def parse_header(line)
    if match = line.match(/^(.+?):\s*(.+)#{@nl}$/)
      key = match[1].to_s.downcase
      
      if key == "set-cookie"
        Knj::Web.parse_set_cookies(match[2]).each do |cookie_data|
          @cookies[cookie_data["name"]] = cookie_data
        end
      end
      
      @resp.headers[key] = [] if !@resp.headers.key?(key)
      @resp.headers[key] << match[2]
    elsif match = line.match(/^HTTP\/([\d\.]+)\s+(\d+)\s+(.+)$/)
      @resp.args[:code] = match[2]
      @resp.args[:http_version] = match[1]
    else
      raise "Could not understand header string: '#{line}'."
    end
  end
  
  def parse_body(line)
    if @resp.args[:http_version] = "1.1"
      return "break" if @resp.header("content-length") == "0"
      
      if @resp.header("transfer-encoding").to_s.downcase == "chunked"
        len = line.strip.hex
        
        if len > 0
          read = @sock.read(len)
          return "break" if read == "" or read == @nl
          @resp.args[:body] += read.force_encoding("utf-8")
        end
        
        nl = @sock.gets
        if len == 0
          if nl == @nl
            return "break"
          else
            raise "Dont know what to do :'-("
          end
        end
        
        raise "Should have read newline but didnt: '#{nl}'." if nl != @nl
      else
        @resp.args[:body] += line.to_s
        return "break" if @resp.header?("content-length") and @resp.args[:body].length >= @resp.header("content-length").to_i
      end
    else
      raise "Dont know how to read HTTP version: '#{@resp.args[:http_version]}'."
    end
    
    @resp.args[:body] = @resp.args[:body].to_s.force_encoding("utf-8")
  end
end

class Knj::Http2::Response
  attr_reader :args
  
  def initialize(args = {})
    @args = args
    @args[:headers] = {} if !@args.key?(:headers)
    @args[:body] = "" if !@args.key?(:body)
  end
  
  def headers
    return @args[:headers]
  end
  
  def header(key)
    return false if !@args[:headers].key?(key)
    return @args[:headers][key].first.to_s
  end
  
  def header?(key)
    return true if @args[:headers].key?(key) and @args[:headers][key].first.to_s.length > 0
    return false
  end
  
  def code
    return @args[:code]
  end
  
  def http_version
    return @args[:http_version]
  end
  
  def body
    return @args[:body]
  end
end