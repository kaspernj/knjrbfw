class Knj::Nvidia_settings
	attr_reader :data
	
	def initialize(data = {})
		@data = data
		@power_mizer_modes = {
			"adaptive" => 0,
			"performance" => 1
		}
	end
	
	def self.list
		res = Knj::Os.shellcmd("nvidia-settings -q gpus")
		ret = []
		
		res.scan(/\[gpu:(\d+)\]/) do |gpu|
			ret << Knj::Nvidia_settings.new(
				"gpu_no" => gpu[0]
			)
		end
		
		return ret
	end
	
	def power_mizer_mode=(newval)
		if @power_mizer_modes[newval] == nil
			raise "No such power-mizer-mode."
		end
		
		cmd = "nvidia-settings -a [gpu:#{@data["gpu_no"]}]/GPUPowerMizerMode=#{@power_mizer_modes[newval]}"
		res = Knj::Os.shellcmd(cmd)
		
		if res.index("assigned value") == nil
			raise res.strip
		end
	end
end