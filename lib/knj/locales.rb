#Fixes a bug in the 'locale'-gem when running under KDE and 'LANGUAGE'-ENV-variable is set but empty.
ENV["LANGUAGE"] = "en_GB" if ENV["LANGUAGE"] == ""

#This module can be used to handel various language-stuff.
module Knj::Locales
  LANG_CONVERTIONS = {
    "en" => "en_GB"
  }
  
  #Returns the primary locale, secondary locale and the two put together.
  #===Examples
  # Knj::Locales.lang #=> {"first" => "en", "second" => "GB", "full" => "en_GB"}
  def self.lang
    locale_str = self.locale.to_s.strip
    locale_str = "en_GB" if locale_str.empty?
    
    #Sometimes language can be 'en'. Convert that to 'en_GB' if that is so.
    locale_str = Knj::Locales::LANG_CONVERTIONS[locale_str] if Knj::Locales::LANG_CONVERTIONS.key?(locale_str)
    
    match = locale_str.match(/^([a-z]{2})_([A-Z]{2})/)
    raise "Could not understand language: '#{locale_str}'." if !match
        
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
    
    case f
      when "da", "de", "es", "pl", "sv"
        dec = ","
        thousand = "."
        csv_delimiter = ";"
      else
        dec = "."
        thousand = ","
        csv_delimiter = ","
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
    
    require "php4r"
    return Php4r.number_format(num_str, dec, lc["decimal_point"], lc["thousands_sep"])
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
    elsif ENV["LANG"]
      return ENV["LANG"]
    end
    
    return "en_GB"
  end
end