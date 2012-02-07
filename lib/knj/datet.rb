require "time"

class Knj::Datet
  attr_accessor :time
  
  def initialize(time = Time.now)
    @time = time
  end
  
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
  
  def add_years(years = 1)
    next_year = @time.year + years.to_i
    @time = self.stamp(:datet => false, :year => next_year)
    return self
  end
  
  #Returns the number of days in the current month.
  def days_in_month
    return 29 if month == 2 and Date.gregorian_leap?(self.year)
    
    #Thanks to ActiveSupport: http://rubydoc.info/docs/rails/2.3.8/ActiveSupport/CoreExtensions/Time/Calculations
    days_in_months = [nil, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    return days_in_months[@time.month]
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
  
  def hour
    return @time.hour
  end
  
  def min
    return @time.min
  end
  
  def year=(newyear)
    @time = self.stamp(:datet => false, :year => newyear)
  end
  
  def month
    @mode = :months
    return @time.month
  end
  
  def date
    @mode = :days
    return @time.day
  end
  
  def wday_mon
    wday = @time.wday
    return 0 if wday == 6
    return wday - 1
  end
  
  def date=(newday)
    newday = newday.to_i
    
    if newday <= 0
      self.add_days(newday - 1)
    else
      @time = self.stamp(:datet => false, :day => newday)
    end
    
    return self
  end
  
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
  
  def min=(newmin)
    @time = self.stamp(:datet => false, :min => newmin.to_i)
  end
  
  def sec=(newsec)
    @time = self.stamp(:datet => false, :sec => newsec.to_i)
  end
  
  alias :day :date
  
  def month=(newmonth)
    @time = self.stamp(:datet => false, :month => newmonth)
  end
  
  def arg_to_time(datet)
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
    secs = arg_to_time(timeobj).to_i
    
    if secs > @time.to_i
      return -1
    elsif secs < @time.to_i
      return 1
    else
      return 0
    end
  end
  
  def add_something(val)
    val = -val if @addmode == "-"
    return self.add_hours(val) if @mode == :hours
    return self.add_days(val) if @mode == :days
    return self.add_months(val) if @mode == :months
    return self.add_mins(val) if @mode == :mins
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
  
  def mins
    @mode = :mins
    return self
  end
  
  def days
    @mode = :days
    return self
  end
  
  def months
    @mode = :months
    return self
  end
  
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
  
  def dbstr(args = {})
    str = "%04d" % @time.year.to_s + "-" + "%02d" % @time.month.to_s + "-" + "%02d" % @time.day.to_s
    
    if !args.key?(:time) or args[:time]
      str << " " + "%02d" % @time.hour.to_s + ":" + "%02d" % @time.min.to_s + ":" + "%02d" % @time.sec.to_s
    end
    
    return str
  end
  
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
  
  def self.parse(str)
    return Knj::Datet.from_dbstr(str)
  end
  
  def self.is_nullstamp?(stamp)
    return true if !stamp or stamp == "0000-00-00" or stamp == "0000-00-00 00:00:00" or stamp.to_s.strip == ""
    return false
  end
  
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
  
  #Returns a hash with the month-no as key and month-name as value.
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
  
  def code
    return "#{"%04d" % @time.year}#{"%02d" % @time.month}#{"%02d" % @time.day}#{"%02d" % @time.hour}#{"%02d" % @time.min}#{"%02d" % @time.sec}#{"%05d" % @time.usec}"
  end
  
  def unixt
    return @time.to_i
  end
  
  alias :to_i :unixt
  
  def httpdate
    require "time"
    return @time.httpdate
  end
  
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
  
  def offset_str
    offset_info_data = self.offset_info
    return "#{offset_info_data[:sign]}#{"%02d" % offset_info_data[:hours]}#{"%02d" % offset_info_data[:mins]}"
  end
  
  #Returns 'localtime' as of 1.9 - even in 1.8 which does it different.
  def localtime_str
    return "#{"%04d" % @time.year}-#{"%02d" % @time.month}-#{"%02d" % @time.day} #{"%02d" % @time.hour}:#{"%02d" % @time.min}:#{"%02d" % @time.sec} #{self.offset_str}"
  end
end