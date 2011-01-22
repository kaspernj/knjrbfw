module Knj::Locales
	def self.lang
		begin
			locale = _session[:locale]
		rescue NameError
			#_session method does not exist - continue.
		end
		
		if !locale
			if ENV["LANGUAGE"]
				locale = ENV["LANGUAGE"]
			end
		end
		
		if !locale
			raise "Could not figure out locale."
		end
		
		raise "Could not understand language: #{ENV["LANGUAGE"]}." if !match = locale.to_s.match(/^([a-z]{2})_([A-Z]{2})/)
				
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
			when "da", "es", "de", "sv"
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
		num_str = num_str.to_s.gsub(lc["thousands_sep"], "").gsub(lc["decimal_point"], ".").to_f
		return num_str
	end
	
	def self.number_out(num_str, dec = 2)
		lc = Knj::Locales.localeconv
		return Knj::Php.number_format(num_str, dec, lc["decimal_point"], lc["thousands_sep"])
	end
end