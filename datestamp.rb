class Knj::Datestamp
	def self.in(time = Time.new)
		if Knj::Php.is_numeric(time)
			time = Time.at(time.to_i)
		elsif time.is_a?(String)
			time = Time.local(*ParseDate.parsedate(time))
		end
		
		return time
	end
	
	def self.dbstr(time = nil)
		if !time
			time = Time.new
		end
		
		if Knj::Php.is_numeric(time)
			time = Time.at(time.to_i)
		elsif time.is_a?(String)
			begin
				time = Time.local(*ParseDate.parsedate(time))
			rescue => e
				raise sprintf("Could not parse date: %s", time.to_s)
			end
		else
			raise "Could not figure out given argument: #{time.class.name}"
		end
		
		return "%04d" % time.year.to_s + "-" + "%02d" % time.month.to_s + "-" + "%02d" % time.day.to_s + " " + "%02d" % time.hour.to_s + ":" + "%02d" % time.min.to_s + ":" + "%02d" % time.sec.to_s
	end
	
	def self.from_dbstr(date_string)
		if Knj::Datestamp.is_nullstamp?(date_string)
			return 0
		end
		
		return Time.local(*ParseDate.parsedate(date_string))
	end
	
	def self.out(time = nil, args = {})
		Knj::ArrayExt.hash_sym(args)
		
		time = Time.new if !time
		
		if Knj::Php.is_numeric(time)
			time = Time.at(time.to_i)
		elsif time.is_a?(String)
			time = Time.at(Php.strtotime(time))
		end
		
		str = ""
		
		if !args.has_key?(:date) or args[:date] == true
			str += "%02d" % time.day.to_s + "/" + "%02d" % time.month.to_s + " " + "%04d" % time.year.to_s
		end
			
		if !args.has_key?(:time) or args[:time] == true
			str += " " + "%02d" % time.hour.to_s + ":" + "%02d" % time.min.to_s
		end
		
		return str
	end
	
	def self.in(timestr)
		if match = timestr.to_s.match(/^(\d+)\/(\d+) (\d+)/)
			timestr = timestr.gsub(match[0], "")
			date = match[1]
			month = match[2]
			year = match[3]
		else
			raise sprintf(_("Wrong format: %s"), timestr)
		end
		
		if match = timestr.match(/\s*(\d+):(\d+)/)
			timestr = timestr.gsub(match[0], "")
			hour = match[1]
			minute = match[2]
		end
		
		datestr = ""
		datestr = "#{year}-#{month}-#{date}" if date and month and year
		datestr += " #{hour}:#{minute}" if hour and minute
		
		return Knj::Datestamp.from_dbstr(datestr)
	end
	
	def self.is_nullstamp?(datestamp)
		return true if datestamp.is_a?(String) and datestamp == "0000-00-00 00:00:00"
		return false
	end
end