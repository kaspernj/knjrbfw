module Knj::Locales
	def self.lang
		raise "Could not understand language: #{ENV["LANGUAGE"]}." if !match = ENV["LANGUAGE"].match(/^([a-z]{2})_([A-Z]{2})/)
		return {
			"first" => match[1],
			"second" => match[2],
			"full" => match[1] + "_" + match[2]
		}
	end
	
	def self.localeconv
		f = Knj::Locales.lang["first"]
		
		dec = "."
		thousand = ","
		
		case f
			when "da", "es", "de"
				dec = ","
				thousand = "."
			when "en"
				#do nothing.
			else
				raise "Cant figure out numbers for language: #{f}."
		end
		
		return {
			"decimal_point" => dec,
			"thousands_sep" => thousand
		}
	end
	
	def self.number_in(num_str)
		lc = Knj::Locales.localeconv
		num_str = num_str.gsub(lc["thousands_sep"], "").gsub("decimal_point", ".").to_f
		return num_str
	end
	
	def self.number_out(num_str, dec = 2)
		lc = Knj::Locales.localeconv
		return Php.number_format(num_str, dec, lc["decimal_point"], lc["thousands_sep"])
	end
end