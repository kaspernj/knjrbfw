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
	
	def add_hours(hours = 1)
		hours = hours.to_i
		cur_hour = @time.hour
		next_hour = cur_hour + hours
		
		if next_hour >= 24
			@time = self.add_days(1).stamp(:datet => false, :hour => 0)
			hours_left = (hours - 1) - (24 - cur_hour)
			return self.add_hours(hours_left) if hours_left > 0
		elsif next_hour < 0
			@time = self.add_days(-1).stamp(:datet => false, :hour => 23)
			hours_left = hours + cur_hour + 1
			self.add_hours(hours_left) if hours_left < 0
		else
			@time = self.stamp(:datet => false, :hour => next_hour)
		end
		
		return self
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
		diw = @time.strftime("%w").to_i
		if diw == 0
			diw = 6
		else
			diw -= 1
		end
		
		return diw
	end
	
	def day_name
		return @time.strftime("%A")
	end
	
	def month_name
		return @time.strftime("%B")
	end
	
	def year
		return @time.year
	end
	
	def year=(newyear)
		@time = self.stamp(:datet => false, :year => newyear)
	end
	
	def month
		return @time.month
	end
	
	def month=(newmonth)
		@time = self.stamp(:datet => false, :month => newmonth)
	end
	
	def >=(datet)
		return self.time.to_i >= datet.time.to_i
	end
	
	def add_something(val)
		val = -val if @addmode == "-"
		return self.add_hours(val) if @mode == :hours
		return self.add_days(val) if @mode == :days
		raise "No such mode: #{@mode}"
	end
	
	def -(val)
		@addmode = "-"
		self.add_something(val)
	end
	
	def +(val)
		@addmode = "+"
		self.add_something(val)
	end
	
	def hours
		@mode = :hours
		return self
	end
	
	def days
		@mode = :days
		return self
	end
	
	def stamp(args)
		vars = {:year => @time.year, :month => @time.month, :day => @time.day, :hour => @time.hour, :min => @time.min, :sec => @time.sec}
		
		args.each do |key, value|
			vars[key.to_sym] = value.to_i if key != :datet
		end
		
		time = Time.gm(vars[:year], vars[:month], vars[:day], vars[:hour], vars[:min], vars[:sec])
		
		if !args.has_key?(:datet) or args[:datet]
			return Datet.new(time)
		end
		
		return time
	end
	
	def dbstr
		return "%04d" % @time.year.to_s + "-" + "%02d" % @time.month.to_s + "-" + "%02d" % @time.day.to_s + " " + "%02d" % @time.hour.to_s + ":" + "%02d" % @time.min.to_s + ":" + "%02d" % @time.sec.to_s
	end
	
	def self.from_dbstr(date_string)
		if Datestamp.is_nullstamp?(date_string)
			return false
		end
		
		return Datet.new(Time.local(*ParseDate.parsedate(date_string)))
	end
	
	def out(args = {})
		str = ""
		date_shown = false
		time_shown = false
		
		if !args.has_key?(:date) or args[:date]
			date_shown = true
			str += "%02d" % @time.day.to_s + "/" + "%02d" % @time.month.to_s + " " + "%04d" % @time.year.to_s
		end
		
		if !args.has_key?(:time) or args[:time]
			time_shown = true
			str += " - " if date_shown
			str += "%02d" % @time.hour.to_s + ":" + "%02d" % @time.min.to_s
		end
		
		return str
	end
	
	def self.in(timestr)
		if match = timestr.to_s.match(/^(\d+)\/(\d+) (\d+)/)
			#MySQL date format
			timestr = timestr.gsub(match[0], "")
			date = match[1]
			month = match[2]
			year = match[3]
			
			if match = timestr.match(/\s*(\d+):(\d+)/)
				#MySQL datetime format
				timestr = timestr.gsub(match[0], "")
				hour = match[1]
				minute = match[2]
			end
			
			return Datet.new(Time.gm(year, month, date, hour, minute))
		elsif match = timestr.to_s.match(/^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})(\d{5})$/)
			#Datet.code format
			return Datet.new(Time.gm(match[1], match[2], match[3], match[4], match[5], match[6], match[7]))
		end
		
		raise Errors::InvalidData.new(sprintf(_("Wrong format: %s"), timestr))
	end
	
	def self.months_arr
		return Dictionary[
			1, _("January"),
			2, _("February"),
			3, _("March"),
			4, _("April"),
			5, _("May"),
			6, _("June"),
			7, _("July"),
			8, _("August"),
			9, _("September"),
			10, _("October"),
			11, _("November"),
			12, _("December")
		]
	end
	
	def to_s
		return @time.to_s
	end
	
	def code
		return "#{"%04d" % @time.year}#{"%02d" % @time.month}#{"%02d" % @time.day}#{"%02d" % @time.hour}#{"%02d" % @time.min}#{"%02d" % @time.sec}#{"%05d" % @time.usec}"
	end
	
	def unixt
		return @time.to_i
	end
	
	alias :to_i :unixt
end