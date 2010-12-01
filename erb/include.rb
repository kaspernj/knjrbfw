$eruby_rbyte = {}

class ERuby
	def self.import(filename)
		filename = File.expand_path(filename)
		pwd = Dir.pwd
		Dir.chdir(File.dirname(filename))
		
		fpath = "#{KnjEruby.filepath}/cache/#{filename.gsub("/", "_").gsub(".", "_")}"
		
		pi = Knj::Php.pathinfo(filename)
		bytepath = pi["dirname"] + "/" + pi["basename"] + ".rbc"
		
		cachename = fpath + ".cache"
		
		filetime = File.mtime(filename)
		
		cacheexists = File.exists?(cachename)
		byteexists = File.exists?(bytepath)
		
		cachetime = File.mtime(cachename) if File.exists?(cachename)
		bytetime = File.mtime(bytepath) if File.exists?(bytepath)
		
		if !cacheexists or filetime > cachetime
			#print "Generating cachefile.<br />\n"
			KnjEruby.load_file(File.basename(filename), {:cachename => cachename})
			cachetime = File.mtime(cachename)
		end
		
		if RUBY_VERSION.slice(0..2) == "1.9" and RubyVM::InstructionSequence.respond_to?(:compile_file)
			if !File.exists?(bytepath) or cachetime > bytetime
				#print "Generating .rbc file.<br />\n"
				res = RubyVM::InstructionSequence.compile_file(filename)
				data = Marshal.dump(res.to_a)
				File.open(bytepath, "w+") do |fp|
					fp.write(data)
				end
			end
			
			if RubyVM::InstructionSequence.respond_to?(:load)
				#print "Loading .rbc file.<br />\n"
				res = Marshal.load(File.read(bytepath))
				RubyVM::InstructionSequence.load(res).eval
			else
				if !$eruby_rbyte[cachename]
					$eruby_rbyte[cachename] = RubyVM::InstructionSequence.new(File.read(cachename))
					#$eruby_rbyte[cachename] = RubyVM::InstructionSequence.compile_file(cachename)
					$eruby_rbyte[cachename].eval
				else
					_buf = ""
					$eruby_rbyte[cachename].eval
					if _buf
						print _buf
					end
				end
			end
		else
			eruby = KnjEruby.load_file(File.basename(filename), {:cachename => cachename})
			print eruby.evaluate
		end
		
		Dir.chdir(pwd)
	end
end

class KnjEruby < Erubis::Eruby
	include Erubis::StdoutEnhancer
	
	@headers = [
		["Content-Type", "text/html; charset=utf-8"]
	]
	@filepath = File.dirname(Knj::Os::realpath(__FILE__))
	@connects = {}
	
	def self.fcgi=(newvalue); @fcgi = newvalue; end
	def self.fcgi; return @fcgi; end
	def self.connects; return @connects; end
	def self.headers; return @headers; end
	
	def self.print_headers(args = {})
		header_str = ""
		
		@headers.each do |header|
			header_str += "#{header[0]}: #{header[1]}\n"
		end
		
		header_str += "\n"
		self.reset_headers if @fcgi
		return header_str
	end
	
	def self.has_status_header?
		@headers.each do |header|
			if header[0] == "Status"
				return true
			end
		end
		
		return false
	end
	
	def self.reset_connects
		@connects = {}
	end
	
	def self.reset_headers
		@headers = [
			["Content-Type", "text/html; charset=utf-8"]
		]
	end
	
	def self.header(key, value)
		@headers << [key, value]
	end
	
	def self.filepath
		return @filepath
	end
	
	def self.connect(signal, &block)
		@connects[signal] = [] if !@connects[signal]
		@connects[signal] << block
	end
	
	def self.printcont(tmp_out, args = {})
		if @fcgi
			@fcgi.print self.print_headers
			tmp_out.rewind
			@fcgi.print tmp_out.read.to_s
		else
			if args[:io]
				old_out = $stdout
				$stdout = args[:io]
			else
				$stdout = STDOUT
			end
			
			print self.print_headers if !args.has_key?(:with_headers) and args[:with_headers]
			tmp_out.rewind
			print tmp_out.read
		end
	end
	
	def self.load_return(filename, args = {})
		retio = StringIO.new
		args[:io] = retio
		KnjEruby.load(filename, args)
		retio.rewind
		return retio.read
	end
	
	def self.load(filename, args = {})
		begin
			tmp_out = StringIO.new
			$stdout = tmp_out
			ERuby.import(filename)
			
			if KnjEruby.connects["exit"]
				KnjEruby.connects["exit"].each do |block|
					block.call
				end
			end
			
			KnjEruby.printcont(tmp_out, args)
		rescue SystemExit => e
			KnjEruby.printcont(tmp_out, args)
		rescue Exception => e
			begin
				if KnjEruby.connects["error"]
					KnjEruby.connects["error"].each do |block|
						block.call(e)
					end
				end
			rescue SystemExit => e
				exit
			rescue Exception => e
				#An error occurred while trying to run the on-error-block - show this as an normal error.
				print "\n\n<pre>\n\n"
				print "<b>#{CGI.escapeHTML(e.class.name)}: #{CGI.escapeHTML(e.message)}</b>\n\n"
				
				#Lets hide all the stuff in what is not the users files to make it easier to debug.
				bt = e.backtrace
				#to = bt.length - 9
				#bt = bt[0..to]
				
				bt.each do |line|
					print CGI.escapeHTML(line) + "\n"
				end
				
				print "</pre>"
			end
			
			print "\n\n<pre>\n\n"
			print "<b>#{CGI.escapeHTML(e.class.name)}: #{CGI.escapeHTML(e.message)}</b>\n\n"
			
			#Lets hide all the stuff in what is not the users files to make it easier to debug.
			bt = e.backtrace
			to = bt.length - 9
			bt = bt[0..to]
			
			bt.reverse.each do |line|
				print CGI.escapeHTML(line) + "\n"
			end
			
			if tmp_out
				KnjEruby.printcont(tmp_out, args)
			end
		end
	end
end