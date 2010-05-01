module Knj
	class Date
		def self.dbstr(time = Time.new)
			return "%04d" % time.year.to_s + "-" + "%02d" % time.month.to_s + "-" + "%02d" % time.day.to_s + " " + "%02d" % time.hour.to_s + ":" + "%02d" % time.min.to_s + ":" + "%02d" % time.sec.to_s
		end
		
		def self.from_dbstr(date_string)
			return Time.local(*ParseDate.parsedate(date_string))
		end
		
		def self.out(time = Time.new, paras = {})
			str = ""
			
			if !paras.has_key?("date") or paras["date"] == true
				str += "%02d" % time.day.to_s + "/" + "%02d" % time.month.to_s + " " + "%04d" % time.year.to_s
			end
			 
			if !paras.has_key?("time") or paras["time"] == true
				str += " " + "%02d" % time.hour.to_s + ":" + "%02d" % time.min.to_s
			end
			
			return str
		end
	end
end