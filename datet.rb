class Knj::Datet
	attr_accessor :time
	
	def initialize(time = Time.new)
		@time = time
	end
	
	def find(incr, args)
		count = 0
		while true
			if args[:day_in_week]
				if self.day_in_week == args[:day_in_week]
					return self
				end
			end
			
			if incr == :day
				self.add_days(1)
			elsif incr == :month
				self.add_months(1)
			else
				raise "Invalid increment: " + incr.to_s
			end
			
			count += 1
			if count > 999
				raise "Endless loop?"
			end
		end
	end
	
	def add_days(days = 1)
		days = days.to_i
		dim = self.days_in_month
		cur_day = @time.day
		next_day = cur_day + days
		
		if next_day > dim
			@time = self.add_months(1).stamp(:datet => false, :day => 1)
			days_left = (days - 1) - (dim - cur_day)
			self.add_days(days_left) if days_left > 0
		else
			@time = self.stamp(:datet => false, :day => next_day)
		end
		
		return self
	end
	
	def add_months(months = 1)
		months = months.to_i
		cur_month = @time.month
		cur_day = @time.day
		next_month = cur_month + months.to_i
		
		if next_month > 12
			@time = self.add_years(1).stamp(:datet => false, :month => 1, :day => 1)
			months_left = (months - 1) - (12 - cur_month)
			return self.add_months(months_left) if months_left > 0
		else
			@time = self.stamp(:datet => false, :month => next_month, :day => 1)
		end
		
		dim = self.days_in_month
		
		if dim > cur_day
			@time = self.stamp(:datet => false, :day => dim)
		else
			@time = self.stamp(:datet => false, :day => cur_day)
		end
		
		return self
	end
	
	def add_years(years = 1)
		next_year = @time.year + years.to_i
		@time = self.stamp(:datet => false, :year => next_year)
		return self
	end
	
	def days_in_month
		return (Date.new(@time.year, 12, 31) << (12 - @time.month)).day.to_i
	end
	
	def day_in_week
		return @time.strftime("%w").to_i
	end
	
	def day_name
		return @time.strftime("%A")
	end
	
	def stamp(args)
		vars = {:year => @time.year, :month => @time.month, :day => @time.day, :hour => @time.hour, :min => @time.min, :sec => @time.sec}
		
		args.each do |key, value|
			vars[key.to_sym] = value.to_i if key != :datet
		end
		
		time = Time.gm(vars[:year], vars[:month], vars[:day], vars[:hour], vars[:min], vars[:sec])
		
		if !args.has_key?(:datet) or args[:datet]
			return Datet.new(time)
		else
			return time
		end
	end
	
	def dbstr
		return "%04d" % @time.year.to_s + "-" + "%02d" % @time.month.to_s + "-" + "%02d" % @time.day.to_s + " " + "%02d" % @time.hour.to_s + ":" + "%02d" % @time.min.to_s + ":" + "%02d" % @time.sec.to_s
	end
	
	def out(args = {})
		if !args.has_key?(:date) or args[:date] == true
			str += "%02d" % @time.day.to_s + "/" + "%02d" % @time.month.to_s + " " + "%04d" % @time.year.to_s
		end
			
		if !args.has_key?(:time) or args[:time] == true
			str += " " + "%02d" % @time.hour.to_s + ":" + "%02d" % @time.min.to_s
		end
		
		return str
	end
	
	def to_s
		return @time.to_s
	end
end