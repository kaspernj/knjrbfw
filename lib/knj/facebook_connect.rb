class Knj::Facebook_connect
  attr_reader :args
  
  def initialize(args)
    require "#{$knjpath}http"
    require "#{$knjpath}http2"
    
    @args = args
    
    raise "No app-ID given." if !@args[:app_id]
    raise "No app-secret given." if !@args[:app_secret]
  end
  
  def login(args)
    hash = {}
    Knj::Php.parse_str(args[:token], hash)
    hash = Knj::Php.ksort(hash)
    
    payload = ""
    hash.each do |key, val|
      next if key == "sig"
      payload += "#{key}=#{val}"
    end
    
    raise "Invalid payload or signature." if Digest::MD5.hexdigest("#{payload}#{@args[:app_secret]}") != hash["sig"]
    
    http = Knj::Http.new(
      "host" => "graph.facebook.com",
      "ssl" => true
    )
    data = http.get("/me?access_token=#{hash["access_token"]}")
    @args[:token] = hash["access_token"]
    data = {:token => hash["access_token"], :access_token => JSON.parse(data["data"])}
    
    if args[:profile_picture]
      pic_data = http.get("/#{data[:access_token]["id"]}/picture?type=large")
      pic_obj = Magick::Image.from_blob(pic_data["data"].to_s)[0]
      data[:pic] = pic_obj
    end
    
    return data
  end
  
  def wall_post(args)
    raise "No token in arguments." if !@args[:token]
    
    http = Knj::Http.new(
      "host" => "graph.facebook.com",
      "ssl" => true
    )
    
    post_data = {}
    
    args_keys = [:link, :object_attachment, :picture, :caption, :name, :description, :message, :media]
    args_keys.each do |key|
      if args.key?(key) and args[key]
        post_data[key] = args[key]
      end
    end
    
    res = http.post("/me/feed?access_token=#{@args[:token]}", post_data)
    raise res["data"].to_s.strip if !res["response"].is_a?(Net::HTTPOK)
  end
end