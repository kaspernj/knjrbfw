#This file can be symlinked and thereby easily translated by POEdit. Further more the static methods can be used for stuff.
module Knj::Locales
  #Returns an array of translated day-names ('_'-method must exist!).
  #===Examples
  # Knj::Locales.days_arr #=> ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
  def self.days_arr
    return [_("Monday"), _("Tuesday"), _("Wednesday"), _("Thursday"), _("Friday"), _("Saturday"), _("Sunday")]
  end
  
  #Returns an array of short translated day-names.
  #===Examples
  # Knj::Locales.days_short_arr #=> ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
  def self.days_short_arr
    return [_("Mon"), _("Tue"), _("Wed"), _("Thu"), _("Fri"), _("Sat"), _("Sun")]
  end
  
  #Returns an array of translated month-names.
  #===Examples
  # Knj::Locales.months_arr #=> ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
  def self.months_arr
    return [_("January"), _("February"), _("March"), _("April"), _("May"), _("June"), _("July"), _("August"), _("September"), _("October"), _("November"), _("December")]
  end
  
  #Returns an array of translate 'ago'-strings. View the source to see which.
  def self.ago_strings
    return {
      :year_ago_str => _("%s year ago"),
      :years_ago_str => _("%s years ago"),
      :month_ago_str => _("%s month ago"),
      :months_ago_str => _("%s months ago"),
      :day_ago_str => _("%s day ago"),
      :days_ago_str => _("%s days ago"),
      :hour_ago_str => _("%s hour ago"),
      :hours_ago_str => _("%s hours ago"),
      :min_ago_str => _("%s minute ago"),
      :mins_ago_str => _("%s minutes ago"),
      :sec_ago_str => _("%s second ago"),
      :secs_ago_str => _("%s seconds ago"),
      :right_now_str => _("right now")
    }
  end
end