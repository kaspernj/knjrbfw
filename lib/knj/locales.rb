module Knj::Locales
  #Returns the primary locale, secondary locale and the two put together.
  def self.lang
    match = self.locale.to_s.match(/^([a-z]{2})_([A-Z]{2})/)
    raise "Could not understand language: #{self.locale}." if !match
        
    return {
      "first" => match[1],
      "second" => match[2],
      "full" => "#{match[1]}_#{match[2]}"
    }
  end
  
  #Returns various localized information about the environment.
  def self.localeconv
    f = Knj::Locales.lang["first"]
    
    dec = "."
    thousand = ","
    csv_delimiter = ","
    
    case f
      when "da", "es", "de", "sv"
        dec = ","
        thousand = "."
        csv_delimiter = ";"
      when "en"
        #do nothing.
      else
        raise "Cant figure out numbers for language: #{f}."
    end
    
    return {
      "decimal_point" => dec,
      "thousands_sep" => thousand,
      "csv_delimiter" => csv_delimiter
    }
  end
  
  #Returns a float from the formatted string according to the current locale.
  def self.number_in(num_str)
    lc = Knj::Locales.localeconv
    num_str = num_str.to_s.gsub(lc["thousands_sep"], "").gsub(lc["decimal_point"], ".").to_f
    return num_str
  end
  
  #Returns the given number as a formatted string according to the current locale.
  def self.number_out(num_str, dec = 2)
    lc = Knj::Locales.localeconv
    return Knj::Php.number_format(num_str, dec, lc["decimal_point"], lc["thousands_sep"])
  end
  
  #Returns the current locale for the current environment.
  def self.locale
    begin
      return _session[:locale] if _session[:locale].to_s.strip.length > 0
    rescue NameError
      #ignore.
    end
    
    if Thread.current[:locale]
      return Thread.current[:locale]
    elsif $locale
      return $locale
    elsif ENV["LANGUAGE"]
      return ENV["LANGUAGE"]
    end
    
    raise "Could not figure out locale."
  end
end