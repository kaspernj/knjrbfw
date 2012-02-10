$knj_require_info = {}

class Object
  alias_method :require_knj, :require
  
  def require(path)
    stat = require_knj(path)
    
    if stat and !$knj_require_info.key?(path)
      $knj_require_info[path] = {:caller => caller}
    end
    
    return stat
  end
end