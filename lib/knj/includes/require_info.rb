Knj::REQUIRE_INFO = {}

class Object
  alias_method :require_knj, :require
  
  def require(path)
    stat = require_knj(path)
    
    if stat and !Knj::REQUIRE_INFO.key?(path)
      Knj::REQUIRE_INFO[path] = {:caller => caller}
    end
    
    return stat
  end
end