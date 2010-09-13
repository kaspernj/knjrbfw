class Knj::Sysuser
	def initialize(data)
		@data = data
	end
	
	def self.list(paras = {})
		cont = File.read("/etc/passwd")
		
		list = []
		cont.split("\n").each do |line|
			linearr = line.split(":")
			
			list << Sysuser.new(
				"nick" => linearr[0],
				"home" => linearr[5],
				"shell" => linearr[6]
			)
		end
		
		return list
	end
	
	def [](key)
		raise "No such key: " + key if !@data.has_key?(key)
		return @data[key]
	end
end