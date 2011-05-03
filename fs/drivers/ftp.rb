class Knj::Fs::Ftp
	def self.args
		return [
			{
				"title" => "Hostname",
				"name" => "texhost"
			},
			{
				"title" => "Port",
				"name" => "texport"
			},
			{
				"title" => "Username",
				"name" => "texusername"
			},
			{
				"title" => "Password",
				"name" => "texpassword",
				"type" => "password"
			},
			{
				"title" => "Passive?",
				"name" => "chepassive",
				"type" => "checkbox"
			}
		]
	end
	
	def initialize(args)
		@args = args
		raise "Stub!"
	end
end