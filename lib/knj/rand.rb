module Knj::Rand
  def self.range(first, last)
    return first.to_i + rand(last.to_i - first.to_i)
  end
  
  def self.array(arr)
    key = rand(arr.length)
    return arr[key]
  end
end