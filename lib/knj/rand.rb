#This module is used to handel various random handeling.
module Knj::Rand
  #Returns a random integer between the two integers given.
  def self.range(first, last)
    return first.to_i + rand(last.to_i - first.to_i)
  end
  
  #Returns a random element in the given array.
  def self.array(arr)
    key = rand(arr.length)
    return arr[key]
  end
end