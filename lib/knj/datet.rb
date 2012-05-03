require "time"

#This class handels various time- and date-specific behaviour in a friendly way.
#===Examples
# datet = Knj::Datet.new #=> 2012-05-03 20:35:16 +0200
# datet = Knj::Datet.new(Time.now) #=> 2012-05-03 20:35:16 +0200
# datet.months + 5 #=> 2012-10-03 20:35:16 +0200
# datet.days + 64 #=> 2012-12-06 20:35:16 +010
class Knj::Datet
  attr_accessor :time
  
  def initialize(time = Time.now)
    @time = time
  end
  
  #Goes forward day-by-day and stops at a date matching the criteria given.
  #
  #===Examples
  # datet.time #=> 2012-05-03 19:36:08 +0200
  #
  #Try to find next saturday.
  # datet.find(:day, :day_in_week => 5) #=> 2012-05-05 19:36:08 +0200
  #
  #Try to find next wednesday by Time's wday-method.
  # datet.find(:day, :wday => 3) #=> 2012-05-09 19:36:08 +0200
  def find(incr, args)
    count = 0
    while true
      if args[:day_in_week] and self.day_in_week == args[:day_in_week]
        return self
      elsif args[:wday] and self.time.wday == args[:wday].to_i
        return self
      end
      
      if incr == :day
        self.add_days(1)
      elsif incr == :month
        self.add_months(1)
      else
        raise "Invalid increment: #{incr}."
      end
      
      count += 1
      raise "Endless loop?" if count > 999
    end
  end
  
  #Add a given amount of minutes to the object.
  #===Examples
  # datet = Knj::Datet.new #=> 2012-05-03 17:39:45 +0200
  # datet.add_mins(30)
  # datet.time #=> 2012-05-03 18:08:45 +0200
  def add_mins(mins = 1)
    mins = mins.to_i
    cur_mins = @time.min
    next_min  = cur_mins + mins
    
    if next_min >= 60
      @time = self.add_hours(1).stamp(:datet => false, :min => 0)
      mins_left = (mins - 1) - (60 - cur_mins)
      return self.add_mins(mins_left) if mins_left > 0
    elsif next_min < 0
      @time = self.add_hours(-1).stamp(:datet => false, :min => 59)
      mins_left = mins + cur_mins + 1
      self.add_mins(mins_left) if mins_left > 0
    else
      @time = self.stamp(:datet => false, :min => next_min)
    end
    
    return self
  end
  
  #Adds a given amount of hours to the object.
  #===Examples
  # datet = Knj::Datet.new
  # datet.add_hours(2)
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
  
  #Adds a given amount of days to the object.
  #===Examples
  # datet = Knj::Datet.new #=> 2012-05-03 17:42:27 +0200
  # datet.add_days(29)
  # datet.time #=> 2012-06-01 17:42:27 +0200
  def add_days(days = 1)
    days = days.to_i
    return self if days == 0
    dim = self.days_in_month
    cur_day = @time.day
    next_day = cur_day + days
    
    if next_day > dim
      @time = self.add_months(1).stamp(:datet => false, :day => 1)
      days_left = (days - 1) - (dim - cur_day)
      self.add_days(days_left) if days_left > 0
    elsif next_day <= 0
      self.date = 1
      self.add_months(-1)
      @time = self.stamp(:datet => false, :day => self.days_in_month)
      days_left = days + 1
      self.add_days(days_left) if days_left != 0
    else
      @time = self.stamp(:datet => false, :day => next_day)
    end
    
    return self
  end
  
  #Adds a given amount of months to the object.
  #===Examples
  # datet.time #=> 2012-06-01 17:42:27 +0200
  # datet.add_months(2)
  # datet.time #=> 2012-08-01 17:42:27 +0200
  def add_months(months = 1)
    months = months.to_i
    cur_month = @time.month
    cur_day = @time.day
    next_month = cur_month + months.to_i
    
    if next_month > 12
      @time = self.add_years(1).stamp(:datet => false, :month => 1, :day => 1)
      months_left = (months - 1) - (12 - cur_month)
      return self.add_months(months_left) if months_left > 0
    elsif next_month < 1
      @time = self.add_years(-1).stamp(:datet => false, :month => 12)
    else
      @time = self.stamp(:datet => false, :month => next_month, :day => 1)
    end
    
    dim = self.days_in_month
    
    if dim < cur_day
      @time = self.stamp(:datet => false, :day => dim)
    else
      @time = self.stamp(:datet => false, :day => cur_day)
    end
    
    return self
  end
  
  #Adds a given amount of years to the object.
  #===Examples
  # datet.time #=> 2012-08-01 17:42:27 +0200
  # datet.add_years(3)
  # datet.time #> 2014-08-01 17:42:27 +0200
  def add_years(years = 1)
    next_year = @time.year + years.to_i
    @time = self.stamp(:datet => false, :year => next_year)
    return self
  end
  
  #Is a year a leap year in the Gregorian calendar? Copied from Date-class.
  #===Examples
  # if Knj::Datet.gregorian_leap?(2005)
  #   print "2005 is a gregorian-leap year."
  # else
  #   print "2005 is not a gregorian-leap year."
  # end
  def self.gregorian_leap?(y)
    if Date.respond_to?("gregorian_leap?")
      return Date.gregorian_leap?(y)
    elsif y % 4 == 0 && y % 100 != 0
      return true
    elsif y % 400 == 0
      return true
    else
      return false
    end
  end
  
  #Returns the number of days in the month.
  #===Examples
  # datet = Knj::Datet.new
  # print "There are #{datet.days_in_month} days in the current month."
  def days_in_month
    return 29 if month == 2 and Knj::Datet.gregorian_leap?(self.year)
    
    #Thanks to ActiveSupport: http://rubydoc.info/docs/rails/2.3.8/ActiveSupport/CoreExtensions/Time/Calculations
    days_in_months = [nil, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    return days_in_months[@time.month]
  end
  
  #Returns the day in the week. Monday being 1 and sunday being 6.
  def day_in_week
    diw = @time.strftime("%w").to_i
    if diw == 0
      diw = 6
    else
      diw -= 1
    end
    
    return diw
  end
  
  #Returns the days name as a string.
  def day_name
    return @time.strftime("%A")
  end
  
  #Returns the months name as a string.
  def month_name
    return @time.strftime("%B")
  end
  
  #Returns the year as an integer.
  def year
    return @time.year
  end
  
  #Returns the hour as an integer.
  def hour
    return @time.hour
  end
  
  #Returns the minute as an integer.
  def min
    return @time.min
  end
  
  #Changes the year to the given year.
  # datet = Knj::Datet.now #=> 2014-05-03 17:46:11 +0200
  # datet.year = 2005
  # datet.time #=> 2005-05-03 17:46:11 +0200
  def year=(newyear)
    @time = self.stamp(:datet => false, :year => newyear)
  end
  
  #Returns the month as an integer.
  def month
    @mode = :months
    return @time.month
  end
  
  #Returns the day in month as an integer.
  def date
    @mode = :days
    return @time.day
  end
  
  #Returns the weekday of the week as an integer. Monday being the first and sunday being the last.
  def wday_mon
    wday = @time.wday
    return 0 if wday == 6
    return wday - 1
  end
  
  #Changes the date to a given date.
  #===Examples
  # datet.time #=> 2005-05-03 17:46:11 +0200
  # datet.date = 8
  # datet.time #=> 2005-05-08 17:46:11 +0200
  def date=(newday)
    newday = newday.to_i
    
    if newday <= 0
      self.add_days(newday - 1)
    else
      @time = self.stamp(:datet => false, :day => newday)
    end
    
    return self
  end
  
  #Changes the hour to a given new hour.
  #===Examples
  # datet.time #=> 2012-05-09 19:36:08 +0200
  # datet.hour = 5
  # datet.time #=> 2012-05-09 05:36:08 +0200
  def hour=(newhour)
    newhour = newhour.to_i
    day = @time.day
    
    loop do
      break if newhour >= 0
      day += -1
      newhour += 24
    end
    
    loop do
      break if newhour < 24
      day += 1
      newhour += -24
    end
    
    @time = self.stamp(:datet => false, :hour => newhour)
    
    self.date = day if day != @time.day
    return self
  end
  
  #Changes the minute to a given new minute.
  #===Examples
  # datet.time #=> 2012-05-09 05:36:08 +0200
  # datet.min = 35
  # datet.time #=> 2012-05-09 05:35:08 +0200
  def min=(newmin)
    @time = self.stamp(:datet => false, :min => newmin.to_i)
  end
  
  #Changes the second to a given new second.
  #===Examples
  # datet.time #=> 2012-05-09 05:35:08 +0200
  # datet.sec = 20
  # datet.time #=> 2012-05-09 05:35:20 +0200
  def sec=(newsec)
    @time = self.stamp(:datet => false, :sec => newsec.to_i)
  end
  
  alias :day :date
  
  #Changes the month to a given new month.
  #===Examples
  # datet.time #=> 2012-05-09 05:35:20 +0200
  # datet.month = 7
  # datet.time #=> 2012-07-09 05:35:20 +0200
  def month=(newmonth)
    @time = self.stamp(:datet => false, :month => newmonth)
  end
  
  #Turns the given argument into a new Time-object.
  #===Examples
  # time = Knj::Datet.arg_to_time(datet) #=> <Time>-object
  # time = Knj::Datet.arg_to_time(Time.now) #=> <Time>-object
  def self.arg_to_time(datet)
    if datet.is_a?(Knj::Datet)
      return datet.time
    elsif datet.is_a?(Time)
      return datet
    else
      raise "Could not handle object of class: '#{datet.class.name}'."
    end
  end
  
  include Comparable
  def <=>(timeobj)
    secs = Knj::Datet.arg_to_time(timeobj).to_i
    
    if secs > @time.to_i
      return -1
    elsif secs < @time.to_i
      return 1
    else
      return 0
    end
  end
  
  #This method is used for adding values to the object based on the current set mode.
  #===Examples
  #Add two months to the datet.
  # datet.months
  # datet.add_something(2)
  def add_something(val)
    val = -val if @addmode == "-"
    return self.add_years(val) if @mode == :years
    return self.add_hours(val) if @mode == :hours
    return self.add_days(val) if @mode == :days
    return self.add_months(val) if @mode == :months
    return self.add_mins(val) if @mode == :mins
    raise "No such mode: #{@mode}"
  end
  
  #Minus something.
  #===Examples
  # datet.months - 5
  # datet.years - 2
  def -(val)
    @addmode = "-"
    self.add_something(val)
  end
  
  #Add something.
  #===Examples
  # datet.months + 5
  # datet.months + 2
  def +(val)
    @addmode = "+"
    self.add_something(val)
  end
  
  #Sets the mode to hours and gets ready to plus or minus.
  #===Examples
  # datet.time #=> 2005-05-08 17:46:11 +0200
  # datet.hours + 5
  # datet.time #=> 2005-05-08 22:46:11 +0200
  def hours
    @mode = :hours
    return self
  end
  
  #Sets the mode to minutes and gets ready to plus or minus.
  #===Examples
  # datet.time #=> 2005-05-08 22:46:11 +0200
  # datet.mins + 5
  # datet.mins #=> 2005-05-08 22:51:11 +0200
  def mins
    @mode = :mins
    return self
  end
  
  #Sets the mode to days and gets ready to plus or minus.
  #===Examples
  # datet.time #=> 2005-05-08 22:51:11 +0200
  # datet.days + 26
  # datet.time #=> 2005-06-03 22:51:11 +0200
  def days
    @mode = :days
    return self
  end
  
  #Sets the mode to months and gets ready to plus or minus.
  #===Examples
  # datet.time #=> 2005-06-03 22:51:11 +0200
  # datet.months + 14
  # datet.time #=> 2006-08-01 22:51:11 +0200
  def months
    @mode = :months
    return self
  end
  
  #Sets the mode to years and gets ready to plus or minus.
  #===Examples
  # datet.time #=> 2006-08-01 22:51:11 +0200
  # datet.years + 5
  # datet.time #=> 2011-08-01 22:51:11 +0200
  def years
    @mode = :years
    return self
  end
  
  #Returns a new Knj::Datet- or Time-object based on the arguments.
  #===Examples
  # time = datet.stamp(:datet => false, :min => 15, :day => 5) #=> 2012-07-05 05:15:20 +0200
  def stamp(args)
    vars = {:year => @time.year, :month => @time.month, :day => @time.day, :hour => @time.hour, :min => @time.min, :sec => @time.sec}
    
    args.each do |key, value|
      vars[key.to_sym] = value.to_i if key != :datet
    end
    
    time = Time.local(vars[:year], vars[:month], vars[:day], vars[:hour], vars[:min], vars[:sec])
    
    if !args.key?(:datet) or args[:datet]
      return Knj::Datet.new(time)
    end
    
    return time
  end
  
  #Returns the time as a database-valid string.
  #===Examples
  # datet.time #=> 2011-08-01 22:51:11 +0200
  # datet.dbstr #=> "2011-08-01 22:51:11"
  # datet.dbstr(:time => false) #=> "2011-08-01"
  def dbstr(args = {})
    str = "%04d" % @time.year.to_s + "-" + "%02d" % @time.month.to_s + "-" + "%02d" % @time.day.to_s
    
    if !args.key?(:time) or args[:time]
      str << " " + "%02d" % @time.hour.to_s + ":" + "%02d" % @time.min.to_s + ":" + "%02d" % @time.sec.to_s
    end
    
    return str
  end
  
  #Parses the date from a database-format.
  #===Examples
  # datet = Knj::Datet.from_dbstr("2011-08-01 22:51:11")
  # datet.time #=> 2011-08-01 22:51:11 +0200
  def self.from_dbstr(date_string)
    if date_string.is_a?(Time)
      return Knj::Datet.new(date_string)
    elsif date_string.is_a?(Date)
      return Knj::Datet.new(date_string.to_time)
    end
    
    return false if Knj::Datet.is_nullstamp?(date_string)
    
    require "#{$knjpath}autoload/parsedate"
    return Knj::Datet.new(Time.local(*ParseDate.parsedate(date_string.to_s)))
  end
  
  #Alias for 'from_dbstr'.
  def self.parse(str)
    return Knj::Datet.from_dbstr(str)
  end
  
  #Returns true of the given stamp is a 'nullstamp'.
  #===Examples
  # Knj::Datet.is_nullstamp?("0000-00-00") #=> true
  # Knj::Datet.is_nullstamp?("0000-00-00 00:00:00") #=> true
  # Knj::Datet.is_nullstamp?("") #=> true
  # Knj::Datet.is_nullstamp?("1985-06-17") #=> false
  def self.is_nullstamp?(stamp)
    return true if !stamp or stamp == "0000-00-00" or stamp == "0000-00-00 00:00:00" or stamp.to_s.strip == ""
    return false
  end
  
  #Returns the day of the year (0-365) as an integer.
  def day_of_year
    return @time.strftime("%j").to_i
  end
  
  #Returns how many days there is between the two timestamps given as an integer.
  #===Examples
  # d1 = Knj::Datet.new #=> 2012-05-03 18:04:12 +0200
  # d2 = Knj::Datet.new #=> 2012-05-03 18:04:16 +0200
  # d2.months + 5 #=> 2012-10-03 18:04:16 +0200
  # Knj::Datet.days_between(d1, d2) #=> 153
  def self.days_between(t1, t2)
    raise "Timestamp 2 should be larger than timestamp 1." if t2 < t1
    
    doy1 = t1.day_of_year
    doy2 = t2.day_of_year
    
    yot1 = t1.year
    yot2 = t2.year
    
    if yot1 == yot2
      days_between = doy2 - doy1
      return days_between
    end
    
    upto = 365 - doy1
    after = doy2
    
    return upto + after
  end
  
  #Returns a string based on the date and time.
  #===Examples
  # datet.out #=> "03/05 2012 - 18:04"
  # datet.out(:time => false) #=> "03/05 2012"
  # datet.out(:date => false) #=> "18:04"
  def out(args = {})
    str = ""
    date_shown = false
    time_shown = false
    
    if !args.key?(:date) or args[:date]
      date_shown = true
      str << "%02d" % @time.day.to_s + "/" + "%02d" % @time.month.to_s
      
      if !args.key?(:year) or args[:year]
        str << " " + "%04d" % @time.year.to_s
      end
    end
    
    if !args.key?(:time) or args[:time]
      show_time = true
      
      if args.key?(:zerotime) and !args[:zerotime]
        if @time.hour == 0 and @time.min == 0
          show_time = false
        end
      end
      
      if show_time
        time_shown = true
        str << " - " if date_shown
        str << "%02d" % @time.hour.to_s + ":" + "%02d" % @time.min.to_s
      end
    end
    
    return str
  end
  
  #Parses various objects into Knj::Datet-objects.
  #===Examples
  # datet = Knj::Datet.in("1985-06-17") #=> 1985-06-17 00:00:00 +0200
  # datet = Knj::Datet.in("1985-06-17 10:00:00") #=> 1985-06-17 10:00:00 +0200
  # datet = Knj::Datet.in("17/06 1985 10:00") #=> 1985-06-17 10:00:00 +0200
  def self.in(timestr)
    if timestr.is_a?(Time)
      return Knj::Datet.new(timestr)
    elsif timestr.is_a?(Date)
      return Knj::Datet.new(timestr.to_time)
    elsif timestr.is_a?(Knj::Datet)
      return timestr
    elsif timestr == nil
      return Knj::Datet.in("1970-01-01")
    end
    
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
      
      return Knj::Datet.new(Time.local(year, month, date, hour, minute))
    elsif match = timestr.to_s.match(/^(\d{1,2})\/(\d{1,2})\/(\d{4})$/)
      return Knj::Datet.new(Time.local(match[3], match[2], match[1]))
    elsif match = timestr.to_s.match(/^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})(\d{5,6})$/)
      #Datet.code format
      return Knj::Datet.new(Time.local(match[1], match[2], match[3], match[4], match[5], match[6], match[7]))
    elsif match = timestr.to_s.match(/^\s*(\d{4})-(\d{1,2})-(\d{1,2})(|\s+(\d{2}):(\d{2}):(\d{2})(|\.\d+)\s*)(|\s+(UTC))(|\s+(\+|\-)(\d{2})(\d{2}))$/)
      #Database date format (with possibility of .0 in the end - miliseconds? -knj.
      
      if match[11] and match[13] and match[14]
        if match[12] == "+" or match[12] == "-"
          sign = match[12]
        else
          sign = "+"
        end
        
        utc_str = "#{sign}#{match[13]}:#{match[14]}"
      elsif match[8]
        utc_str = match[8].to_i
      else
        utc_str = nil
      end
      
      time = Time.local(match[1].to_i, match[2].to_i, match[3].to_i, match[5].to_i, match[6].to_i, match[7].to_i, utc_str)
      return Knj::Datet.new(time)
    elsif match = timestr.to_s.match(/^\s*(\d{2,4})-(\d{1,2})-(\d{1,2})(|\s+(\d{1,2}):(\d{1,2}):(\d{1,2})(:(\d{1,2})|)\s*)$/)
      time = Time.local(match[1].to_i, match[2].to_i, match[3].to_i, match[5].to_i, match[6].to_i, match[7].to_i)
      return Knj::Datet.new(time)
    end
    
    raise Knj::Errors::InvalidData.new("Wrong format: '#{timestr}', class: '#{timestr.class.name}'")
  end
  
  #Returns a hash with the month-no as key and month-name as value. It uses the method "_" to translate the months names. So GetText or another method has to be defined.
  def self.months_arr(args = {})
    ret = {
      1 => _("January"),
      2 => _("February"),
      3 => _("March"),
      4 => _("April"),
      5 => _("May"),
      6 => _("June"),
      7 => _("July"),
      8 => _("August"),
      9 => _("September"),
      10 => _("October"),
      11 => _("November"),
      12 => _("December")
    }
    
    if args["short"]
      ret_short = {}
      ret.each do |key, val|
        ret_short[key] = val[0..2]
      end
      
      return ret_short
    end
    
    return ret
  end
  
  #Returns a hash with the day-number as value (starting with 1 for monday). It uses the method "_" to translate the months names.
  def self.days_arr(args = {})
    ret = {
      1 => _("Monday"),
      2 => _("Tuesday"),
      3 => _("Wednesday"),
      4 => _("Thursday"),
      5 => _("Friday"),
      6 => _("Saturday"),
      0 => _("Sunday")
    }
    
    if args["short"]
      ret_short = {}
      ret.each do |key, val|
        ret_short[key] = val[0..2]
      end
      
      return ret_short
    end
    
    return ret
  end
  
  #Returns the month-number for a given string (starting with 1 for january).
  #===Examples
  # Knj::Datet.month_str_to_no("JaNuArY") #=> 1
  # Knj::Datet.month_str_to_no("DECEMBER") #=> 12
  # Knj::Datet.month_str_to_no("kasper") #=> <Error>-raised
  def self.month_str_to_no(str)
    ret = {
      "jan" => 1,
      "january" => 1,
      "feb" => 2,
      "february" => 2,
      "mar" => 3,
      "march" => 3,
      "apr" => 4,
      "april" => 4,
      "may" => 5,
      "jun" => 6,
      "june" => 6,
      "jul" => 7,
      "july" => 7,
      "aug" => 8,
      "august" => 8,
      "sep" => 9,
      "september" => 9,
      "oct" => 10,
      "october" => 11,
      "nov" => 11,
      "november" => 11,
      "dec" => 12,
      "december" => 12
    }
    
    str = str.to_s.downcase.strip
    return ret[str] if ret.key?(str)
    raise "No month to return from that string: '#{str}'."
  end
  
  def loc_wday
    return _(@time.strftime("%A"))
  end
  
  def loc_wday_small
    return _(@time.strftime("%a"))
  end
  
  def loc_month
    return _(@time.strftime("%B"))
  end
  
  def to_s
    return @time.to_s
  end
  
  #This returns a code-string that can be used to recreate the Knj::Datet-object.
  #===Examples
  # code = datet.code #=> "1985061710000000000"
  # newdatet = Knj::Datet.in(code) #=> 1985-06-17 10:00:00 +0200
  def code
    return "#{"%04d" % @time.year}#{"%02d" % @time.month}#{"%02d" % @time.day}#{"%02d" % @time.hour}#{"%02d" % @time.min}#{"%02d" % @time.sec}#{"%05d" % @time.usec}"
  end
  
  #Returns the unix timestamp for this object.
  #===Examples
  # datet.unixt #=> 487843200
  # datet.to_i #=> 487843200
  def unixt
    return @time.to_i
  end
  
  alias :to_i :unixt
  
  #Returns the HTTP-date that can be used in headers and such.
  #===Examples
  # datet.httpdate #=> "Mon, 17 Jun 1985 08:00:00 GMT"
  def httpdate
    require "time"
    return @time.httpdate
  end
  
  #Returns various information about the offset as a hash.
  #===Examples
  # datet.time #=> 1985-06-17 10:00:00 +0200
  # datet.offset_info #=> {:sign=>"+", :hours=>2, :mins=>0, :secs=>0}
  def offset_info
    offset_secs = @time.gmt_offset
    
    offset_hours = (offset_secs.to_f / 3600.0).floor
    offset_secs -= offset_hours * 3600
    
    offset_minutes = (offset_secs.to_f / 60.0).floor
    offset_secs -= offset_minutes * 60
    
    if offset_hours > 0
      sign = "+"
    else
      sign = ""
    end
    
    return {
      :sign => sign,
      :hours => offset_hours,
      :mins => offset_minutes,
      :secs => offset_secs
    }
  end
  
  #Returns the offset as a string.
  #===Examples
  # datet.offset_str #=> "+0200"
  def offset_str
    offset_info_data = self.offset_info
    return "#{offset_info_data[:sign]}#{"%02d" % offset_info_data[:hours]}#{"%02d" % offset_info_data[:mins]}"
  end
  
  #Returns 'localtime' as of 1.9 - even in 1.8 which does it different.
  #===Examples
  # datet.localtime_str #=> "1985-06-17 10:00:00 +0200"
  def localtime_str
    return "#{"%04d" % @time.year}-#{"%02d" % @time.month}-#{"%02d" % @time.day} #{"%02d" % @time.hour}:#{"%02d" % @time.min}:#{"%02d" % @time.sec} #{self.offset_str}"
  end
  
  #Returns a human readable string based on the difference from the current time and date.
  #===Examples
  # datet.time #=> 1985-06-17 10:00:00 +0200
  # datet.ago_str #=> "27 years ago"
  # datet = Knj::Datet.new #=> 2012-05-03 20:31:58 +0200
  # datet.ago_str #=> "18 seconds ago"
  def ago_str(args = {})
    args = {
      :year_ago_str => "%s year ago",
      :years_ago_str => "%s years ago",
      :month_ago_str => "%s month ago",
      :months_ago_str => "%s months ago",
      :day_ago_str => "%s day ago",
      :days_ago_str => "%s days ago",
      :hour_ago_str => "%s hour ago",
      :hours_ago_str => "%s hours ago",
      :min_ago_str => "%s minute ago",
      :mins_ago_str => "%s minutes ago",
      :sec_ago_str => "%s second ago",
      :secs_ago_str => "%s seconds ago",
      :right_now_str => "right now"
    }.merge(args)
    
    secs_ago = Time.now.to_i - @time.to_i
    mins_ago = secs_ago.to_f / 60.0
    hours_ago = mins_ago / 60.0
    days_ago = hours_ago / 24.0
    months_ago = days_ago / 30.0
    years_ago = months_ago / 12.0
    
    if years_ago > 0.9 and years_ago < 1.5
      return sprintf(args[:year_ago_str], years_ago.to_i)
    elsif years_ago >= 1.5
      return sprintf(args[:years_ago_str], years_ago.to_i)
    elsif months_ago > 0.9 and months_ago < 1.5
      return sprintf(args[:month_ago_str], months_ago.to_i)
    elsif months_ago >= 1.5
      return sprintf(args[:months_ago_str], months_ago.to_i)
    elsif days_ago > 0.9 and days_ago < 1.5
      return sprintf(args[:day_ago_str], days_ago.to_i)
    elsif days_ago >= 1.5
      return sprintf(args[:days_ago_str], days_ago.to_i)
    elsif hours_ago > 0.9 and hours_ago < 1.5
      return sprintf(args[:hour_ago_str], hours_ago.to_i)
    elsif hours_ago >= 1.5
      return sprintf(args[:hours_ago_str], hours_ago.to_i)
    elsif mins_ago > 0.9 and mins_ago < 1.5
      return sprintf(args[:min_ago_str], mins_ago.to_i)
    elsif mins_ago >= 1.5
      return sprintf(args[:mins_ago_str], mins_ago.to_i)
    elsif secs_ago >= 0.1 and secs_ago < 1.5
      return sprintf(args[:sec_ago_str], secs_ago.to_i)
    elsif secs_ago >= 1.5
      return sprintf(args[:secs_ago_str], secs_ago.to_i)
    end
    
    return args[:right_now_str]
  end
  
  #Returns the object as a human understandable string.
  #===Examples
  # datet.time #=> 2012-05-03 20:31:58 +0200
  # datet.human_str #=> "20:31"
  def human_str(args = {})
    args = {
      :time => true,
      :number_endings => {
        0 => "th",
        1 => "st",
        2 => "nd",
        3 => "rd",
        4 => "th",
        5 => "th",
        6 => "th",
        7 => "th",
        8 => "th",
        9 => "th"
      }
    }.merge(args)
    
    now = Time.now
    
    #Generate normal string.
    date_str = ""
    
    if now.day != @time.day and now.month == @time.month and now.year == @time.year
      last_digit = @time.day.to_s[-1, 1].to_i
      
      if ending = args[:number_endings][last_digit]
        #ignore.
      else
        ending = "."
      end
      
      date_str << "#{@time.day}#{ending} "
    elsif now.day != @time.day or now.month != @time.month or now.year != @time.year
      date_str << "#{@time.day}/#{@time.month} "
    end
    
    if now.year != @time.year
      date_str << "#{@time.year} "
    end
    
    if args[:time]
      date_str << "#{@time.hour}:#{"%02d" % @time.min}"
    end
    
    return date_str
  end
end