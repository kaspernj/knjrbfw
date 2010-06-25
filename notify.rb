module Knj
	class Notify
		def self.send(args)
			cmd = "notify-send"
			
			if args["time"]
				if !Php.is_numeric(args["time"])
					raise "Time is not numeric."
				end
				
				cmd += " -t " + args["time"].to_s
			end
			
			cmd += " " + Strings.UnixSafe(args["title"]) + " " + Strings.UnixSafe(args["msg"])
			
			system(cmd)
		end
	end
end