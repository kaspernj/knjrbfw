class Knj::Mailobj
	def initialize(args = {})
		@args = {
			"smtp_host" => "localhost",
			"smtp_port" => 25,
			"smtp_user" => nil,
			"smtp_passwd" => nil,
			"smtp_domain" => ENV["HOSTNAME"]
		}
		
		if args.is_a?(Hash)
			args.each do |key, value|
				@args[key] = value
			end
		end
		
		self.send if @args["send"]
	end
	
	def html=(value)
		@args["html"] = value
	end
	
	def text=(value)
		@args["text"] = value
	end
	
	def from=(value)
		@args["from"] = value
	end
	
	def subject=(value)
		@args["subject"] = value
	end
	
	def to=(value)
		@args["to"] = value.untaint
	end
	
	def send
		raise "No email has been defined to send to." if !@args["to"]
		raise "No subject has been defined." if !@args["subject"]
		raise "No content has been defined." if !@args["text"] and !@args["html"]
		
		require "mail"
		
		mail = Mail.new
		mail.to = @args["to"]
		mail.subject = @args["subject"]
		mail.date = Time.new
		mail.from = @args["from"] if @args["from"]
		
		if @args["html"]
			tha_html = @args["html"]
			mail.html_part do
				content_type "text/html; charset=UTF-8"
				body tha_html
			end
		end
		
		if @args["text"]
			tha_text = @args["text"]
			mail.text_part do
				body tha_text
			end
		end
		
		smtp_start = Net::SMTP.new(@args["smtp_host"], @args["smtp_port"])
		smtp_start.enable_ssl if @args["ssl"]
		smtp_start.enable_starttls if @args["tls"]
		
		if !@args["smtp_domain"]
			if @args["smtp_host"]
				@args["smtp_domain"] = @args["smtp_host"]
			else
				raise "SMTP domain not given."
			end
		end
		
		smtp_start.start(@args["smtp_domain"], @args["smtp_user"], @args["smtp_passwd"]) do |smtp|
			smtp.send_message(mail.to_s, @args["from"], @args["to"])
		end
	end
end