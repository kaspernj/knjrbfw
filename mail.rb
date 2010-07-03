module Knj
	class Mail
		def initialize(paras = {})
			@paras = {
				"smtp_host" => "localhost",
				"smtp_port" => 25,
				"smtp_user" => nil,
				"smtp_passwd" => nil,
				"smtp_domain" => ENV["HOSTNAME"]
			}
			
			paras.each do |key, value|
				@paras[key] = value
			end
			
			if @paras["send"]
				self.send
			end
		end
		
		def html=(value)
			@paras["html"] = value
		end
		
		def text=(value)
			@paras["text"] = value
		end
		
		def from=(value)
			@paras["from"] = value
		end
		
		def subject=(value)
			@paras["subject"] = value
		end
		
		def to=(value)
			@paras["to"] = value.untaint
		end
		
		def send
			if !@paras["to"]
				raise "No email has been defined to send to."
			end
			
			if !@paras["subject"]
				raise "No subject has been defined."
			end
			
			if !@paras["text"] and !@paras["html"]
				raise "No content has been defined."
			end
			
			mail = TMail::Mail.new
			mail.to = @paras["to"]
			mail.subject = @paras["subject"]
			mail.date = Time.new
			
			if @paras["from"]
				mail.from = @paras["from"]
			end
			
			if @paras["html"]
				mail.set_content_type("text", "html")
				mail.body = @paras["html"]
			elsif @paras["text"]
				mail.body = @paras["text"]
			end
			
			smtp_start = Net::SMTP.new(@paras["smtp_host"], @paras["smtp_port"])
			
			if @paras["ssl"]
				smtp_start.enable_ssl
			end
			
			if !@paras["smtp_domain"]
				if @paras["smtp_host"]
					@paras["smtp_domain"] = @paras["smtp_host"]
				else
					raise "SMTP domain not given."
				end
			end
			
			smtp_start.start(@paras["smtp_domain"], @paras["smtp_user"], @paras["smtp_passwd"]) do |smtp|
				smtp.send_message(mail.to_s, @paras["from"], @paras["to"])
			end
		end
	end
end