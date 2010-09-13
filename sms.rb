class Knj::Sms
	def initialize(opts)
		@opts = Knj::ArrayExt.hash_sym(opts)
		
		@opts.each do |key, value|
			if key == :type
				if value == "bibob" or value == "cbb" or value == "smsd_db"
					@type = value
					
					if @type == "smsd_db"
						@db = Knj::Db.new(@opts[:knjdb_args])
						Knj::Thread.new(@db) do |db|
							db.query("SELECT * FROM outbox WHERE id = 0") #ping!
							sleep 15
						end
					end
				else
					raise "Not supported: " + value.to_s
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
				"cellphone" => @opts[:user],
				"password" => Knj::Php.md5(@opts[:pass]),
				"smsTo" => {"string" => number},
				"smscontents" => msg,
				"sendDate" => Knj::Php.date("Y-m-d"),
				"deliveryReport" => "0",
				"fromNumber" => @opts[:user]
			})
			
			if result.sendMessageResult.errorString.to_s != "Ingen fejl."
				raise "Could not send SMS: (" + result.sendMessageResult.errorCode.to_s + "): " + result.sendMessageResult.errorString.to_s
			end
		elsif @type == "smsd_db"
			@db.insert("outbox", {
				"number" => number,
				"text" => msg,
				"insertdate" => Knj::Php.date("Y-m-d H:i:s")
			})
		else
			raise "Not supported: " + @type
		end
	end
end