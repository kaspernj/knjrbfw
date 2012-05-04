#Contains various methods for handeling CSV-stuff.
class Knj::Csv
  #Converts a given array to a CSV-string.
  #===Examples
  # str = Knj::Csv.arr_to_csv([1, 2, 3], ";", "'") #=> "'1';'2';'3'\n"
  def self.arr_to_csv(arr, del, encl)
    raise "No delimiter given." if !del
    raise "No enclosure given." if !encl
    
    str = ""
    first = true
    arr.each do |val|
      if first
        first = false
      else
        str << del
      end
      
      val = val.to_s.encode("utf-8").gsub(del, "").gsub(encl, "")
      str << "#{encl}#{val}#{encl}"
    end
    
    str << "\n"
    
    return str
  end
end