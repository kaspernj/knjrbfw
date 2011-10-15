class Knj::Facebook_connect
  def initialize(args)
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
    data = {:access_token => JSON.parse(data["data"])}
    
    if args[:profile_picture]
      pic_data = http.get("/#{data[:access_token]["id"]}/picture?type=large")
      pic_obj = Magick::Image.from_blob(pic_data["data"].to_s)[0]
      data[:pic] = pic_obj
    end
    
    return data
  end
end