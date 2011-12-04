class WEBrick::HTTPRequest
  #Function to clean up memory - knj.
  def destroy
    arr_hash = [@cookies, @accept, @accept_charset, @accept_encoding, @accept_language, @attributes]
    arr_hash.each do |val|
      if val and (val.is_a?(Array) or val.is_a?(Hash))
        val.clear
      end
    end
    
    @config = nil
    @cookies = nil
    @accept = nil
  end
end

class WEBrick::HTTPResponse
  #Function to clean up memory - knj.
  def destroy
    arr_hash = [@cookies, @header]
    arr_hash.each do |val|
      if val and (val.is_a?(Array) or val.is_a?(Hash))
        val.clear
      end
    end
    
    @config = nil
    @header = nil
    @cookies = nil
  end
end