class Knj::Degulesider
  def initialize(args = {})
    @args = args
    @http = Knj::Http.new(
      "host" => "www.degulesider.dk"
    )
  end
  
  def search(sargs)
    url = "/search/#{Knj::Php.urlencode(sargs[:where])}/-/1/"
    
    html = @http.get(url)
    ret = []
    
    tbody_match = html["data"].match(/<tbody class='resultBody([\s\S]+?)<\/tbody>/)
    tbody_match[1].scan(/<tr id='res(\d+)'([\s\S]+?)<\/tr>/) do |match|
      res = {}
      
      if title_match = match[1].match(/<h2><a\s+class="fn".*>(.+)<\/a><\/h2>/)
        res[:name] = title_match[1]
      end
      
      if phone_match = match[1].match(/<div class="phones"><ul class="linkList"><li>(Mob.|)\s*([\d\s]+)<\/li><\/ul><\/div>/)
        if phone_match[1] == "Mob."
          res[:mobile] = phone_match[2].gsub(/\s+/, "")
        else
          raise "No such phone-mode: #{phone_match[1]}"
        end
      end
      
      if city_match = match[1].match(/'locality'>(.+)<\/span>/)
        res[:city] = city_match[1]
      end
      
      if category_match = match[1].match(/class='categoryLink'>(.+)<\/a>/)
        res[:category] = category_match[1]
      end
      
      ret << res
    end
    
    return ret
  end
end