class Knj::Facebook_connect
  attr_reader :args
  
  def initialize(args)
    require "#{$knjpath}http"
    require "#{$knjpath}http2"
    
    @args = args
    
    raise "No app-ID given." if !@args[:app_id]
    raise "No app-secret given." if !@args[:app_secret]
  end
  
  def base64_urldecode(str)
    return Base64.decode64("#{str.tr("-_", "+/")}=")
  end
  
  def get(http, url)
    resp = http.get(url)
    
    if resp.body.length > 0
      begin
        jdata = JSON.parse(resp.body)
        raise "#{jdata["error"]["type"]}: #{jdata["error"]["message"]}" if jdata["error"]
      rescue JSON::ParserError
        #ignore
      end
    end
    
    return {:json => jdata, :resp => resp, :headers => resp.headers, :body => resp.body}
  end
  
  def validate_cookie(cookie)
    data = cookie.split(".", 2)
    enc_sig, payload = data[0], data[1]
    
    sig = self.base64_urldecode(enc_sig).unpack("H*").first
    data = self.base64_urldecode(payload)
    data = JSON.parse(data)
    
    raise "Unknown algorithm: '#{data["algorithm"]}'." if data["algorithm"] != "HMAC-SHA256"
    exp_sig = OpenSSL::HMAC.hexdigest("sha256", @args[:app_secret], payload)
    
    raise "Bad signed JSON signature." if sig != exp_sig
    
    return data
  end
  
  def token_from_cookie(http, cookie = nil)
    if @token
      return @token
    end
    
    raise "No token set and no cookie given." if !@args[:cookie]
    
    data = self.validate_cookie(@args[:cookie])
    resp = self.get(http, "oauth/access_token?client_id=#{Knj::Web.urlenc(@args[:app_id])}&client_secret=#{Knj::Web.urlenc(@args[:app_secret])}&redirect_uri=&code=#{Knj::Web.urlenc(data["code"])}")
    
    match = resp[:body].match(/access_token=(.+)&expires=(\d+)/)
    raise "No access token was given." if !match
    atoken = match[1]
    @token = atoken
    @expires = match[2]
    
    return atoken
  end
  
  def login(args = {})
    http = Knj::Http2.new(
      :host => "graph.facebook.com",
      :ssl => true
    )
    
    atoken = self.token_from_cookie(http, @args[:cookie])
    
    url = "me?access_token=#{Knj::Web.urlenc(atoken)}"
    resp = self.get(http, url)
    data = {"user" => resp[:json]}
    
    if args[:profile_picture]
      pic_data = self.get(http, "#{data["user"]["id"]}/picture?type=large")
      pic_obj = Magick::Image.from_blob(pic_data[:body].to_s)[0]
      data["pic"] = pic_obj
    end
    
    return data
  end
  
  def wall_post(args)
    http = Knj::Http2.new(
      :host => "graph.facebook.com",
      :ssl => true
    )
    
    atoken = self.token_from_cookie(http)
    post_data = {}
    
    args_keys = [:link, :object_attachment, :picture, :caption, :name, :description, :message, :media]
    args_keys.each do |key|
      if args.key?(key) and args[key]
        post_data[key] = args[key]
      end
    end
    
    res = http.post("/me/feed?access_token=#{atoken}", post_data)
    raise res.body.to_s.strip if res.code.to_s != "200"
  end
end