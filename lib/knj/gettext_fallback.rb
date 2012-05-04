#A fallback GetText implementation that basically returns the given strings, but can be useful for using methods that uses GetText without using an actual GetText implementation.
module GetText
  #Returns the given string.
  def self._(string)
    return string
  end
  
  #Returns the given string.
  def _(string)
    return string
  end
  
  #Returns the given string.
  def gettext(string)
    return string
  end
  
  #Doesnt do anything.
  def bindtextdomain(temp1 = nil, temp2 = nil, temp3 = nil)
    #nothing here.
  end
end