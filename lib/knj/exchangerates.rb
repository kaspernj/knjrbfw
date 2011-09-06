class Knj::Exchangerates
	attr_reader :rates
	
	def initialize(args = {})
		@rates = {}
	end
	
	def base=(data)
		@base = data[:locale].to_s
		self.add_rate(data)
	end
	
	def add_rate(data)
		if !data[:locale] or data[:locale].to_s.length <= 0
			raise "Invalid locale given."
		end
		
		@rates[data[:locale].to_s] = data
	end
	
	def value(locale, floatval)
		floatval = floatval.to_f
		locale = locale.to_s
		
		raise "No such locale: '#{locale}' in '#{@rates.keys.join(",")}'." if !@rates.has_key?(locale)
		
		base_rate = @rates[@base][:rate].to_f
		cur_rate = @rates[locale][:rate].to_f
		
		if base_rate == cur_rate
			return floatval 
		elsif cur_rate < base_rate
			diff = 1 + (base_rate - cur_rate)
			return floatval * diff
		else
			return floatval / cur_rate
		end
	end
end