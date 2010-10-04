class Knj::Mail
	def initialize(paras = {})
		@paras = {
			"smtp_host" => "localhost",
			"smtp_port" => 25,
			"smtp_user" => nil,
			"smtp_passwd" => nil,
			"smtp_domain" => ENV["HOSTNAME"]
		}
		
		if paras.is_a?(Hash)
			paras.each do |key, value|
				@paras[key] = value
			end
		end
		
		self.send if @paras["send"]
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
		raise "No email has been defined to send to." if !@paras["to"]
		raise "No subject has been defined." if !@paras["subject"]
		raise "No content has been defined." if !@paras["text"] and !@paras["html"]
		
		mail = TMail::Mail.new
		mail.to = @paras["to"]
		mail.subject = @paras["subject"]
		mail.date = Time.new
		
		mail.from = @paras["from"] if @paras["from"]
		
		if @paras["html"]
			mail.set_content_type("text", "html")
			mail.body = @paras["html"]
		elsif @paras["text"]
			mail.body = @paras["text"]
		end
		
		smtp_start = Net::SMTP.new(@paras["smtp_host"], @paras["smtp_port"])
		smtp_start.enable_ssl if @paras["ssl"]
		
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