module Knj
	class Sms
		def initialize(opts)
			@opts = opts
			
			opts.each do |pair|
				if (pair[0] == "type")
					if (pair[1] == "bibob" or pair[1] == "cbb" or pair[1] == "smsd_db")
						@type = pair[1]
						
						if @type == "smsd_db"
							@db = Knj::Db.new(@opts["knjdb_args"])
							Thread.new(@db) do |db|
								print "smsd_db ping!!\n"
								db.query("SELECT * FROM outbox WHERE id = 0") #ping!
								sleep 15
							end
						end
					else
						raise "Not supported: " + pair[1].to_s
					end
				end
			end
		end
		
		def send_sms(number, msg)
			if @type == "bibob"
				if !@soap
					require "webrick/https"
					@soap = SOAP::WSDLDriverFactory.new("https://www.bibob.dk/SmsSender.asmx?WSDL").create_rpc_driver
				end
				
				result = @soap.SendMessage({
					"cellphone" => @opts["user"],
					"password" => Php.md5(@opts["pass"]),
					"smsTo" => {"string" => number},
					"smscontents" => msg,
					"sendDate" => Php.date("Y-m-d"),
					"deliveryReport" => "0",
					"fromNumber" => @opts["user"]
				})
				
				if result.sendMessageResult.errorString.to_s != "Ingen fejl."
					raise "Could not send SMS: (" + result.sendMessageResult.errorCode.to_s + "): " + result.sendMessageResult.errorString.to_s
				end
			elsif @type == "smsd_db"
				@db.insert("outbox", {
					"number" => number,
					"text" => msg,
					"insertdate" => Php.date("Y-m-d H:i:s")
				})
			else
				raise "Not supported: " + @type
			end
		end
	end
end