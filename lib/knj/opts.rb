module Knj::Opts
  CONFIG = {
    "table" => "options"
  }
  
  def self.init(arr_opts)
    arr_opts.each do |pair|
      if pair[0] == "knjdb" or pair[0] == "table"
        Knj::Opts::CONFIG[pair[0]] = pair[1]
      end
    end
  end
  
  def self.get(title)
    db = Knj::Opts::CONFIG["knjdb"]
    value = db.select(Knj::Opts::CONFIG["table"], {"title" => title}, {"limit" => 1}).fetch
    
    if !value
      return ""
    else
      return value["value"] if value.key?("value")
      return value[:value] if value.key?(:value)
      raise "Could not figure out of value."
    end
  end
  
  def self.set(title, value)
    db = Knj::Opts::CONFIG["knjdb"]
    result = db.select(Knj::Opts::CONFIG["table"], {"title" => title}, {"limit" => 1}).fetch
    
    if !result
      db.insert(Knj::Opts::CONFIG["table"], {
        "title" => title,
        "value" => value
      })
    else
      id = nil
      id = result["id"] if result.key?("id")
      id = result[:id] if result.key?(:id)
      raise "Could not figure out of ID." if !id
      
      db.update(Knj::Opts::CONFIG["table"], {"value" => value}, {"id" => id})
    end
  end
end