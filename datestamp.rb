module Knj
	class Datestamp
		def self.dbstr(time = nil)
			if !time
				time = Time.new
			end
			
			if Php.is_numeric(time)
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
			if Datestamp.is_nullstamp?(date_string)
				return 0
			end
			
			return Time.local(*ParseDate.parsedate(date_string))
		end
		
		def self.out(time = nil, paras = {})
			if !time
				time = Time.new
			end
			
			if Php.is_numeric(time)
				time = Time.at(time.to_i)
			elsif time.is_a?(String)
				time = Time.at(Php.strtotime(time))
			end
			
			str = ""
			
			if !paras.has_key?("date") or (paras[:date] == true or paras["date"] == true)
				str += "%02d" % time.day.to_s + "/" + "%02d" % time.month.to_s + " " + "%04d" % time.year.to_s
			end
			 
			if (!paras.has_key?("time") and !paras.has_key?(:time)) or (paras[:time] == true or paras["time"] == true)
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
			if date and month and year
				datestr = "#{year}-#{month}-#{date}"
			end
			
			if hour and minute
				datestr += " #{hour}:#{minute}"
			end
			
			return Datestamp.from_dbstr(datestr)
		end
		
		def self.is_nullstamp?(datestamp)
			if datestamp.is_a?(String) and datestamp == "0000-00-00 00:00:00"
				return true
			end
			
			return false
		end
	end
end