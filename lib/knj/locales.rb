#This module can be used to handel various language-stuff.
module Knj::Locales
  #Returns the primary locale, secondary locale and the two put together.
  #===Examples
  # Knj::Locales.lang #=> {"first" => "en", "second" => "GB", "full" => "en_GB"}
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
  #===Examples
  # Knj::Locales.localeconv #=> {"decimal_point" => ".", "thousands_sep" => ",", "csv_delimiter" => ","}
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
  #===Examples
  # Knj::Locales.number_in("123,456.68") #=> 123456.68
  def self.number_in(num_str)
    lc = Knj::Locales.localeconv
    return num_str.to_s.gsub(lc["thousands_sep"], "").gsub(lc["decimal_point"], ".").to_f
  end
  
  #Returns the given number as a formatted string according to the current locale.
  #===Examples
  # Knj::Locales.number_out(123456.68) #=> "123,456.68"
  def self.number_out(num_str, dec = 2)
    lc = Knj::Locales.localeconv
    return Knj::Php.number_format(num_str, dec, lc["decimal_point"], lc["thousands_sep"])
  end
  
  #Returns the current locale for the current environment (_session[:locale] or Thread.current[:locale]).
  #===Examples
  # Knj::Locales.locale #=> 'en_GB'
  # Knj::Locales.locale #=> 'da_DK'
  def self.locale
    begin
      return _session[:locale] if _session[:locale].to_s.strip.length > 0
    rescue NameError
      #ignore.
    end
    
    if Thread.current[:locale]
      return Thread.current[:locale]
    elsif ENV["LANGUAGE"]
      return ENV["LANGUAGE"]
    end
    
    raise "Could not figure out locale."
  end
end