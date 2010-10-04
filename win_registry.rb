class Knj::Win::Registry
	def self.const(type)
		if type == :cur_user
			return Win32::Registry::HKEY_CURRENT_USER
		elsif type == :local_machine
			return Win32::Registry::HKEY_LOCAL_MACHINE
		else
			raise "Unknown type: " + type.to_s
		end
	end
	
	def self.type(in_type)
		return Win32::Registry::REG_SZ if in_type == :sz
		return Win32::Registry::REG_DWORD if in_type == :dword
		return Win32::Registry::REG_BINARY if in_type == :bin
		return nil if in_type == nil
		
		raise "Unknown type: #{in_type}"
	end
	
	def self.get(type, regpath, key, in_type = nil)
		hkey = self.const(type)
		hkey.open(regpath, Win32::Registry::KEY_ALL_ACCESS) do |reg|
			return reg[key, self.type(in_type)].to_s
			
			#reg.each_key do |k, v|
			#	puts k, v
			#end
			#reg.each_value do |k, v|
			#	puts k, v
			#end
			
			#reg_typ, reg_val = reg.read('')
			#return {
			#	:type => reg_typ,
			#	:value => reg_val
			#}
		end
	end
	
	def self.set(type, regpath, key, content = nil, in_type = nil)
		if key.is_a?(Array)
			key.each do |v|
				if v.is_a?(Array)
					self.set(type, regpath, v[0], v[1], v[2])
				elsif v.is_a?(Hash)
					self.set(type, regpath, k, v[:val], v[:type])
				else
					raise "Unknown type: #{v.class.to_s}"
				end
			end
		else
			hkey = self.const(type)
			hkey.create(regpath)
			hkey.open(regpath, Win32::Registry::KEY_ALL_ACCESS) do |reg|
				reg[key.to_s, self.type(in_type)] = content.to_s
			end
		end
	end
end