#This class tries to emulate a browser in Ruby without any visual stuff. Remember cookies, keep sessions alive, reset connections according to keep-alive rules and more.
#===Examples
# Knj::Http2.new(:host => "www.somedomain.com", :port => 80, :ssl => false, :debug => false) do |http|
#  res = http.get("index.rhtml?show=some_page")
#  html = res.body
#  print html
#  
#  res = res.post("index.rhtml?choice=login", {"username" => "John Doe", "password" => 123})
#  print res.body
#  print "#{res.headers}"
# end
class Knj::Http2
  attr_reader :cookies, :args
  
  def initialize(args = {})
    require "#{$knjpath}web"
    
    args = {:host => args} if args.is_a?(String)
    raise "Arguments wasnt a hash." if !args.is_a?(Hash)
    
    @args = args
    @cookies = {}
    @debug = @args[:debug]
    
    require "monitor"
    @mutex = Monitor.new
    
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
    
    if block_given?
      begin
        yield(self)
      ensure
        self.destroy
      end
    end
  end
  
  #Returns boolean based on the if the object is connected and the socket is working.
  #===Examples
  # print "Socket is working." if http.socket_working?
  def socket_working?
    return false if !@sock or @sock.closed?
    
    if @keepalive_timeout and @request_last
      between = Time.now.to_i - @request_last.to_i
      if between >= @keepalive_timeout
        print "Http2: We are over the keepalive-wait - returning false for socket_working?.\n" if @debug
        return false
      end
    end
    
    return true
  end
  
  #Destroys the object unsetting all variables and closing all sockets.
  #===Examples
  # http.destroy
  def destroy
    @args = nil
    @cookies = nil
    @debug = nil
    @mutex = nil
    @uagent = nil
    @keepalive_timeout = nil
    @request_last = nil
    
    @sock.close if @sock and !@sock.closed?
    @sock = nil
    
    @sock_plain.close if @sock_plain and !@sock_plain.closed?
    @sock_plain = nil
    
    @sock_ssl.close if @sock_ssl and !@sock_ssl.closed?
    @sock_ssl = nil
  end
  
  #Reconnects to the host.
  def reconnect
    require "socket"
    print "Http2: Reconnect.\n" if @debug
    
    #Reset variables.
    @keepalive_max = nil
    @keepalive_timeout = nil
    @connection = nil
    @contenttype = nil
    @charset = nil
    
    #Open connection.
    if @args[:proxy]
      print "Http2: Initializing proxy stuff.\n" if @debug
      @sock_plain = TCPSocket.new(@args[:proxy][:host], @args[:proxy][:port])
      @sock = @sock_plain
      
      @sock.write("CONNECT #{@args[:host]}:#{@args[:port]} HTTP/1.0#{@nl}")
      @sock.write("User-Agent: #{@uagent}#{@nl}")
      
      if @args[:proxy][:user] and @args[:proxy][:passwd]
        credential = ["#{@args[:proxy][:user]}:#{@args[:proxy][:passwd]}"].pack("m")
        credential.delete!("\r\n")
        @sock.write("Proxy-Authorization: Basic #{credential}#{@nl}")
      end
      
      @sock.write(@nl)
      
      res = @sock.gets
      raise res if res.to_s.downcase != "http/1.0 200 connection established#{@nl}"
      
      res_empty = @sock.gets
      raise "Empty res wasnt empty." if res_empty != @nl
    else
      print "Http2: Opening socket connection to '#{@args[:host]}:#{@args[:port]}'.\n" if @debug
      @sock_plain = TCPSocket.new(@args[:host], @args[:port].to_i)
    end
    
    if @args[:ssl]
      print "Http2: Initializing SSL.\n" if @debug
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
  
  #Returns a result-object based on the arguments.
  #===Examples
  # res = http.get("somepage.html")
  # print res.body #=> <String>-object containing the HTML gotten.
  def get(addr, args = {})
    @mutex.synchronize do
      args[:addr] = addr
      header_str = "GET /#{addr} HTTP/1.1#{@nl}"
      header_str << self.header_str(self.default_headers(args), args)
      header_str << "#{@nl}"
      
      print "Http2: Writing headers.\n" if @debug
      print "Header str: #{header_str}\n" if @debug
      self.write(header_str)
      
      print "Http2: Reading response.\n" if @debug
      resp = self.read_response(args)
      
      print "Http2: Done with get request.\n" if @debug
      return resp
    end
  end
  
  #Tries to write a string to the socket. If it fails it reconnects and tries again.
  def write(str)
    #Reset variables.
    @length = nil
    @encoding = nil
    self.reconnect if !self.socket_working?
    
    begin
      raise Errno::EPIPE, "The socket is closed." if !@sock or @sock.closed?
      @sock.puts(str)
    rescue Errno::EPIPE #this can also be thrown by puts.
      self.reconnect
      @sock.puts(str)
    end
    
    @request_last = Time.now
  end
  
  #Returns the default headers for a request.
  #===Examples
  # headers_hash = http.default_headers
  # print "#{headers_hash}"
  def default_headers(args = {})
    return args[:default_headers] if args[:default_headers]
    
    headers = {
      "Host" => @args[:host],
      "Connection" => "Keep-Alive",
      "User-Agent" => @uagent
    }
    
    if !@args.key?(:encoding_gzip) or @args[:encoding_gzip]
      headers["Accept-Encoding"] = "gzip"
    else
      #headers["Accept-Encoding"] = "none"
    end
    
    return headers
  end
  
  #This is used to convert a hash to valid post-data recursivly.
  def self.post_convert_data(pdata, args = nil)
    praw = ""
    
    if pdata.is_a?(Hash)
      pdata.each do |key, val|
        praw << "&" if praw != ""
        
        if args and args[:orig_key]
          key = "#{args[:orig_key]}[#{key}]"
        end
        
        if val.is_a?(Hash) or val.is_a?(Array)
          praw << self.post_convert_data(val, {:orig_key => key})
        else
          praw << "#{Knj::Web.urlenc(key)}=#{Knj::Web.urlenc(Knj::Http2.post_convert_data(val))}"
        end
      end
    elsif pdata.is_a?(Array)
      count = 0
      pdata.each do |val|
        if args and args[:orig_key]
          key = "#{args[:orig_key]}[#{count}]"
        else
          key = count
        end
        
        if val.is_a?(Hash) or val.is_a?(Array)
          praw << self.post_convert_data(val, {:orig_key => key})
        else
          praw << "#{Knj::Web.urlenc(key)}=#{Knj::Web.urlenc(Knj::Http2.post_convert_data(val))}"
        end
        
        count += 1
      end
    else
      return pdata.to_s
    end
    
    return praw
  end
  
  #Posts to a certain page.
  #===Examples
  # res = http.post("login.php", {"username" => "John Doe", "password" => 123)
  def post(addr, pdata = {}, args = {})
    @mutex.synchronize do
      print "Doing post.\n" if @debug
      
      praw = Knj::Http2.post_convert_data(pdata)
      
      header_str = "POST /#{addr} HTTP/1.1#{@nl}"
      header_str << self.header_str(self.default_headers(args).merge("Content-Type" => "application/x-www-form-urlencoded", "Content-Length" => praw.length), args)
      header_str << "#{@nl}"
      header_str << praw
      
      print "Header str: #{header_str}\n" if @debug
      
      self.write(header_str)
      return self.read_response(args)
    end
  end
  
  #Posts to a certain page using the multipart-method.
  #===Examples
  # res = http.post_multipart("upload.php", {"normal_value" => 123, "file" => Tempfile.new(?)})
  def post_multipart(addr, pdata, args = {})
    require "digest"
    
    @mutex.synchronize do
      boundary = Digest::MD5.hexdigest(Time.now.to_f.to_s)
      
      #Generate 'praw'-variable with post-content.
      tmp_path = "#{Knj::Os.tmpdir}/knj_http2_post_multiepart_tmp_#{boundary}"
      
      begin
        File.open(tmp_path, "w") do |praw|
          pdata.each do |key, val|
            praw << "--#{boundary}#{@nl}"
            
            if val.class.name == "Tempfile" and val.respond_to?("original_filename")
              praw << "Content-Disposition: form-data; name=\"#{key}\"; filename=\"#{val.original_filename}\";#{@nl}"
              praw << "Content-Length: #{val.to_s.bytesize}#{@nl}"
            elsif val.is_a?(Hash) and val[:filename]
              praw << "Content-Disposition: form-data; name=\"#{key}\"; filename=\"#{val[:filename]}\";#{@nl}"
              
              if val[:content]
                praw << "Content-Length: #{val[:content].to_s.bytesize}#{@nl}"
              elsif val[:fpath]
                praw << "Content-Length: #{File.size(val[:fpath])}#{@nl}"
              else
                raise "Could not figure out where to get content from."
              end
            else
              praw << "Content-Disposition: form-data; name=\"#{key}\";#{@nl}"
              praw << "Content-Length: #{val.to_s.bytesize}#{@nl}"
            end
            
            praw << "Content-Type: text/plain#{@nl}"
            praw << @nl
            
            if val.is_a?(StringIO)
              praw << val.read
            elsif val.is_a?(Hash) and val[:content]
              praw << val[:content].to_s
            elsif val.is_a?(Hash) and val[:fpath]
              File.open(val[:fpath], "r") do |fp|
                begin
                  while data = fp.sysread(4096)
                    praw << data
                  end
                rescue EOFError
                  #ignore.
                end
              end
            else
              praw << val.to_s
            end
            
            praw << @nl
          end
          
          praw << "--#{boundary}--"
        end
        
        
        #Generate header-string containing 'praw'-variable.
        header_str = "POST /#{addr} HTTP/1.1#{@nl}"
        header_str << self.header_str(self.default_headers(args).merge(
          "Content-Type" => "multipart/form-data; boundary=#{boundary}",
          "Content-Length" => File.size(tmp_path)
        ), args)
        header_str << @nl
        
        
        #Debug.
        print "Headerstr: #{header_str}\n" if @debug
        
        
        #Write and return.
        self.write(header_str)
        File.open(tmp_path, "r") do |fp|
          begin
            while data = fp.sysread(4096)
              @sock.write(data)
            end
          rescue EOFError
            #ignore.
          end
        end
        
        return self.read_response(args)
      ensure
        File.unlink(tmp_path) if File.exists?(tmp_path)
      end
    end
  end
  
  #Returns a header-string which normally would be used for a request in the given state.
  def header_str(headers_hash, args = {})
    if @cookies.length > 0 and (!args.key?(:cookies) or args[:cookies])
      cstr = ""
      
      first = true
      @cookies.each do |cookie_name, cookie_data|
        cstr << "; " if !first
        first = false if first
        
        cstr << "#{Knj::Web.urlenc(cookie_data["name"])}=#{Knj::Web.urlenc(cookie_data["value"])}"
      end
      
      headers_hash["Cookie"] = cstr
    end
    
    headers_str = ""
    headers_hash.each do |key, val|
      headers_str << "#{key}: #{val}#{@nl}"
    end
    
    return headers_str
  end
  
  def on_content_call(args, line)
    args[:on_content].call(line) if args.key?(:on_content)
  end
  
  #Reads the response after posting headers and data.
  #===Examples
  # res = http.read_response
  def read_response(args = {})
    @mode = "headers"
    @resp = Knj::Http2::Response.new
    
    loop do
      begin
        if @length and @length > 0 and @mode == "body"
          line = @sock.read(@length)
        else
          line = @sock.gets
        end
        
        print "<#{@mode}>: '#{line}'\n" if @debug
      rescue Errno::ECONNRESET
        print "Http2: The connection was reset while reading - breaking gently...\n" if @debug
        @sock = nil
        break
      end
      
      break if line.to_s == ""
      
      if @mode == "headers" and line == @nl
        print "Changing mode to body!\n" if @debug
        break if @length == 0
        @mode = "body"
        next
      end
      
      if @mode == "headers"
        self.parse_header(line, args)
      elsif @mode == "body"
        self.on_content_call(args, "\r\n")
        stat = self.parse_body(line, args)
        break if stat == "break"
        next if stat == "next"
      end
    end
    
    
    #Check if we should reconnect based on keep-alive-max.
    if @keepalive_max == 1 or @connection == "close"
      @sock.close if !@sock.closed?
      @sock = nil
    end
    
    
    #Check if the content is gzip-encoded - if so: decode it!
    if @encoding == "gzip"
      require "zlib"
      require "iconv"
      io = StringIO.new(@resp.args[:body])
      gz = Zlib::GzipReader.new(io)
      untrusted_str = gz.read
      ic = Iconv.new("UTF-8//IGNORE", "UTF-8")
      valid_string = ic.iconv(untrusted_str + " ")[0..-2]
      @resp.args[:body] = valid_string
    end
    
    
    #Release variables.
    resp = @resp
    @resp = nil
    @mode = nil
    
    raise "No status-code was received from the server.\n\nHeaders:\n#{Knj::Php.print_r(resp.headers, true)}\n\nBody:\n#{resp.args[:body]}" if !resp.args[:code]
    
    if resp.args[:code].to_s == "302" and resp.header?("location") and (!@args.key?(:follow_redirects) or @args[:follow_redirects])
      require "uri"
      uri = URI.parse(resp.header("location"))
      url = uri.path
      url << "?#{uri.query}" if uri.query.to_s.length > 0
      
      args = {:host => uri.host}
      args[:ssl] = true if uri.scheme == "https"
      args[:port] = uri.port if uri.port
      
      print "Redirecting from location-header to '#{url}'.\n" if @debug
      
      if !args[:host] or args[:host] == @args[:host]
        return self.get(url)
      else
        http = Knj::Http2.new(args)
        return http.get(url)
      end
    elsif resp.args[:code].to_s == "500"
      raise "500 - Internal server error: '#{args[:addr]}':\n\n#{resp.body}"
    elsif resp.args[:code].to_s == "403"
      raise Knj::Errors::NoAccess
    else
      return resp
    end
  end
  
  #Parse a header-line and saves it on the object.
  #===Examples
  # http.parse_header("Content-Type: text/html\r\n")
  def parse_header(line, args = {})
    if match = line.match(/^(.+?):\s*(.+)#{@nl}$/)
      key = match[1].to_s.downcase
      
      if key == "set-cookie"
        Knj::Web.parse_set_cookies(match[2]).each do |cookie_data|
          @cookies[cookie_data["name"]] = cookie_data
        end
      elsif key == "keep-alive"
        if ka_max = match[2].to_s.match(/max=(\d+)/)
          @keepalive_max = ka_max[1].to_i
          print "Http2: Keepalive-max set to: '#{@keepalive_max}'.\n" if @debug
        end
        
        if ka_timeout = match[2].to_s.match(/timeout=(\d+)/)
          @keepalive_timeout = ka_timeout[1].to_i
          print "Http2: Keepalive-timeout set to: '#{@keepalive_timeout}'.\n" if @debug
        end
      elsif key == "connection"
        @connection = match[2].to_s.downcase
      elsif key == "content-encoding"
        @encoding = match[2].to_s.downcase
      elsif key == "content-length"
        @length = match[2].to_i
      elsif key == "content-type"
        ctype = match[2].to_s
        if match_charset = ctype.match(/\s*;\s*charset=(.+)/i)
          @charset = match_charset[1].downcase
          @resp.args[:charset] = @charset
          ctype.gsub!(match_charset[0], "")
        end
        
        @ctype = ctype
        @resp.args[:contenttype] = @ctype
      end
      
      if key != "transfer-encoding" and key != "content-length" and key != "connection" and key != "keep-alive"
        self.on_content_call(args, line)
      end
      
      @resp.headers[key] = [] if !@resp.headers.key?(key)
      @resp.headers[key] << match[2]
    elsif match = line.match(/^HTTP\/([\d\.]+)\s+(\d+)\s+(.+)$/)
      @resp.args[:code] = match[2]
      @resp.args[:http_version] = match[1]
    else
      raise "Could not understand header string: '#{line}'.\n\n#{@sock.read(409600)}"
    end
  end
  
  #Parses the body based on given headers and saves it to the result-object.
  # http.parse_body(str)
  def parse_body(line, args)
    if @resp.args[:http_version] = "1.1"
      return "break" if @length == 0
      
      if @resp.header("transfer-encoding").to_s.downcase == "chunked"
        len = line.strip.hex
        
        if len > 0
          read = @sock.read(len)
          return "break" if read == "" or read == @nl
          @resp.args[:body] << read
          self.on_content_call(args, read)
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
        @resp.args[:body] << line.to_s
        self.on_content_call(args, line)
        return "break" if @resp.header?("content-length") and @resp.args[:body].length >= @resp.header("content-length").to_i
      end
    else
      raise "Dont know how to read HTTP version: '#{@resp.args[:http_version]}'."
    end
  end
end

class Knj::Http2::Response
  attr_reader :args
  
  def initialize(args = {})
    @args = args
    @args[:headers] = {} if !@args.key?(:headers)
    @args[:body] = "" if !@args.key?(:body)
  end
  
  #Returns headers given from the host for the result.
  #===Examples
  # headers_hash = res.headers
  def headers
    return @args[:headers]
  end
  
  #Returns a certain header by name or false if not found.
  #===Examples
  # val = res.header("content-type")
  def header(key)
    return false if !@args[:headers].key?(key)
    return @args[:headers][key].first.to_s
  end
  
  #Returns true if a header of the given string exists.
  #===Examples
  # print "No content-type was given." if !http.header?("content-type")
  def header?(key)
    return true if @args[:headers].key?(key) and @args[:headers][key].first.to_s.length > 0
    return false
  end
  
  #Returns the code of the result (200, 404, 500 etc).
  #===Examples
  # print "An internal error occurred." if res.code.to_i == 500
  def code
    return @args[:code]
  end
  
  #Returns the HTTP-version of the result.
  #===Examples
  # print "We are using HTTP 1.1 and should support keep-alive." if res.http_version.to_s == "1.1"
  def http_version
    return @args[:http_version]
  end
  
  #Returns the complete body of the result as a string.
  #===Examples
  # print "Looks like we caught the end of it as well?" if res.body.to_s.downcase.index("</html>") != nil
  def body
    return @args[:body]
  end
  
  #Returns the charset of the result.
  def charset
    return @args[:charset]
  end
  
  #Returns the content-type of the result as a string.
  #===Examples
  # print "This body can be printed - its just plain text!" if http.contenttype == "text/plain"
  def contenttype
    return @args[:contenttype]
  end
end