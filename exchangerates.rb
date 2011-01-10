class Knj::Exchangerates
	def initialize(args = {})
		@rates = {}
	end
	
	def base=(data)
		@rates[data[:locale]] = data
	end
	
	def add_rate(data)
		if !data[:locale] or data[:locale].to_s.length <= 0
			raise "Invalid locale given."
		end
		
		@rates[data[:locale]] = data
	end
	
	def value(locale, floatval)
		raise "No such locale: #{locale}." if !@rates.has_key?(locale)
		
		val = @rates[locale][:rate] * floatval
		return val
	end
end