#This class can be used to send notify-messages through the notify-binary (notify-send or kdialog).
class Knj::Notify
  #Call this method to show notifications.
  #===Examples
  # Knj::Notify.send("msg" => "Hello world!", "time" => 5)
  def self.send(args)
    begin
      toolkit = Knj::Os.toolkit
    rescue
      toolkit = ""
    end
    
    if toolkit == "kde"
      cmd = "kdialog --passivepopup #{Knj::Strings.unixsafe(args["msg"])}"
      
      if args["title"]
        cmd << " --title #{Knj::Strings.unixsafe(args["msg"])}"
      end
      
      if args["time"]
        cmd << " #{Knj::Strings.unixsafe(args["time"])}"
      end
      
      system(cmd)
    else
      cmd = "notify-send"
      
      if args["time"]
        raise "Time is not numeric." if !Php4r.is_numeric(args["time"])
        cmd << " -t #{args["time"]}"
      end
      
      cmd << " #{Knj::Strings.unixsafe(args["title"])} #{Knj::Strings.unixsafe(args["msg"])}"
      system(cmd)
    end
  end
end