module Knj::Opts
  $knjoptions = {
    "table" => "options"
  }
  
  def self.init(arr_opts)
    arr_opts.each do |pair|
      if pair[0] == "knjdb" or pair[0] == "table"
        $knjoptions[pair[0]] = pair[1]
      end
    end
  end
  
  def self.get(title)
    db = $knjoptions["knjdb"]
    value = db.select($knjoptions["table"], {"title" => title}, {"limit" => 1}).fetch
    
    if !value
      return ""
    else
      return value["value"] if value.key?("value")
      return value[:value] if value.key?(:value)
      raise "Could not figure out of value."
    end
  end
  
  def self.set(title, value)
    db = $knjoptions["knjdb"]
    result = db.select($knjoptions["table"], {"title" => title}, {"limit" => 1}).fetch
    
    if !result
      db.insert($knjoptions["table"], {
        "title" => title,
        "value" => value
      })
    else
      id = nil
      id = result["id"] if result.key?("id")
      id = result[:id] if result.key?(:id)
      raise "Could not figure out of ID." if !id
      
      db.update($knjoptions["table"], {"value" => value}, {"id" => id})
    end
  end
end