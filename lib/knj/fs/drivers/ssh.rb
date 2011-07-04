class Knj::Fs::Ssh
	def self.args
		return [
			{
				"title" => "Hostname",
				"name" => "texhostname"
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
			}
		]
	end
	
	def initialize(args)
		@args = args
		raise "Stub!"
	end
end