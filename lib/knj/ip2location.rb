class Knj::Ip2location
  def initialize(args = {})
    @args = args
    @http = Knj::Http.new(
      "host" => "www.ip2location.com",
      "port" => 80
    )
  end
  
  def lookup(ip)
    raise "Invalid IP: #{ip}." if !ip.to_s.match(/^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/)
    
    html = @http.get("/#{ip}")["data"]
    ret = {}
    
    html.scan(/<span id="dgLookup__ctl2_lblI(.+?)">(.+?)<\/span>/) do |match|
      ret[match[0]] = match[1]
    end
    
    return ret
  end
end