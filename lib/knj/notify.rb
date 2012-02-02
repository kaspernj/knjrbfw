class Knj::Notify
  def self.send(args)
    cmd = "notify-send"
    
    if args["time"]
      raise "Time is not numeric." if !Php.is_numeric(args["time"])
      cmd << " -t " + args["time"].to_s
    end
    
    cmd << " " + Strings.UnixSafe(args["title"]) + " " + Strings.UnixSafe(args["msg"])
    system(cmd)
  end
end