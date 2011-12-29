class Knj::Csv
  def self.arr_to_csv(arr, del, encl)
    str = ""
    first = true
    arr.each do |val|
      if first
        first = false
      else
        str += del
      end
      
      val = val.to_s.encode("utf-8").gsub(del, "").gsub(encl, "")
      str += "#{encl}#{val}#{encl}"
    end
    
    str += "\n"
    
    return str
  end
end