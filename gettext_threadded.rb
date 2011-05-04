class Knj::Gettext_threadded
	attr_reader :langs, :args
	
	def initialize(args = {})
		@args = args
		@langs = {}
		load_dir(@args["dir"]) if @args["dir"]
	end
	
	def load_dir(dir)
		check_folders = ["LC_MESSAGES", "LC_ALL"]
		
		Dir.new(dir).each do |file|
			fn = "#{dir}/#{file}"
			if File.directory?(fn) and file.match(/^[a-z]{2}_[A-Z]{2}$/)
				@langs[file] = {} if !@langs[file]
				
				check_folders.each do |fname|
					fpath = "#{dir}/#{file}/#{fname}"
					
					if File.exists?(fpath) and File.directory?(fpath)
						Dir.new(fpath).each do |pofile|
							if pofile.match(/\.po$/)
								pofn = "#{dir}/#{file}/#{fname}/#{pofile}"
								cont = File.read(pofn)
								cont.scan(/msgid\s+\"(.+)\"\nmsgstr\s+\"(.+)\"\n\n/) do |match|
									@langs[file][match[0]] = match[1]
								end
							end
						end
					end
				end
			end
		end
	end
	
	def trans(locale, str)
		locale = locale.to_s
		str = str.to_s
		
		if !@langs.has_key?(locale)
			raise "Locale was not found: '#{locale}' in '#{@langs.keys.join(", ")}'."
		end
		
		return str if !@langs[locale].has_key?(str)
		return @langs[locale][str]
	end
end