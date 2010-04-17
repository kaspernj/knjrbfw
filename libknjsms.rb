require "soap/rpc/driver"

class KnjSMS
	def setOpts(arr_opts)
		arr_opts.each do |pair|
			if (pair[0] == "type")
				if (pair[1] == "bibob" || pair[1] == "cbb")
					@type = pair[1]
				else
					raise "wtf?"
				end
			end
		end
	end
	
	def sendSMS(number, passwd)
		soapob = SOAP::RPC::Driver.new("https://www.bibob.dk/SmsSender.asmx?WSDL");
	end
end