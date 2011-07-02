class Knj::Eruby
	attr_reader :fcgi
	attr_reader :connects, :headers
	
	def initialize(args = {})
		@args = args
		@settings_loaded = true
		@inseq_cache = false
		@inseq_rbc = false
		@java_compile = false
		@compiler = Knj::Compiler.new
		@filepath = File.dirname(Knj::Os::realpath(__FILE__))
		@connects = {}
		
		if RUBY_PLATFORM == "java"
			@java_compile = true
			@eruby_java_cache = {}
		elsif RUBY_VERSION.slice(0..2) == "1.9" and RubyVM::InstructionSequence.respond_to?(:compile_file)
			@eruby_rbyte = {}
			@inseq_cache = true
			
			if RubyVM::InstructionSequence.respond_to?(:load)
				@inseq_rbc = true
			end
		end
		
		@inseq_rbc = false #this is not possible yet in Ruby... maybe in 1.9.3?
		
		self.reset_headers
		self.reset_connects
	end
	
	def import(filename)
		filename = File.expand_path(filename)
		filetime = File.mtime(filename)
		filepath = Knj::Php.realpath(filename)
		fpath = "#{@filepath}/erb/cache/#{filename.gsub("/", "_").gsub(".", "_")}"
		
		cachename = "#{fpath}.cache"
		cacheexists = File.exists?(cachename)
		cachetime = File.mtime(cachename) if File.exists?(cachename)
		
		raise "File does not exist: #{filename}" if !File.exists?(filename)
		
		begin
			if !cacheexists or filetime > cachetime
				Knj::Eruby::Handler.load_file(filepath, {:cachename => cachename})
				cachetime = File.mtime(cachename)
				reload_cache = true
			end
			
			if @java_compile
				if !@eruby_java_cache[cachename] or reload_cache
					@eruby_java_cache[cachename] = File.read(cachename)
				end
				
				eval(@eruby_java_cache[cachename])
			elsif @inseq_cache
				if @inseq_rbc
					pi = Knj::Php.pathinfo(filename)
					bytepath = pi["dirname"] + "/" + pi["basename"] + ".rbc"
					byteexists = File.exists?(bytepath)
					bytetime = File.mtime(bytepath) if File.exists?(bytepath)
					pi.clear
					
					if !File.exists?(bytepath) or cachetime > bytetime
						res = RubyVM::InstructionSequence.compile_file(filename)
						data = Marshal.dump(res.to_a)
						File.open(bytepath, "w+") do |fp|
							fp.write(data)
						end
					end
				end
				
				if @inseq_rbc
					res = Marshal.load(File.read(bytepath))
					RubyVM::InstructionSequence.load(res).eval
				else
					if !@eruby_rbyte[cachename] or @eruby_rbyte[cachename][:time] < filetime
						#@eruby_rbyte[cachename] = RubyVM::InstructionSequence.compile_file(cachename)
						@eruby_rbyte[cachename] = {
							:inseq => RubyVM::InstructionSequence.new(File.read(cachename)),
							:time => Time.new
						}
					end
					
					@eruby_rbyte[cachename][:inseq].eval
				end
			else
				loaded_content = Knj::Eruby::Handler.load_file(filepath, {:cachename => cachename})
				print loaded_content.evaluate
			end
		rescue SystemExit
			#do nothing.
		rescue Exception => e
			self.handle_error(e)
		end
	end
	
	def destroy
		@connects.clear if @connects.is_a?(Hash)
		@headers.clear if @headers.is_a?(Array)
		@eruby_rbyte.clear if @eruby_rbyte.is_a?(Hash)
		@eruby_java_cache.clear if @eruby_java_cache.is_a?(Hash)
		@args.clear if @args.is_a?(Hash)
		
		@connects = nil
		@headers = nil
		@eruby_rbyte = nil
		@eruby_java_cache = nil
		@args = nil
		@inseq_rbc = nil
		@java_compile = nil
	end
	
	def print_headers(args = {})
		header_str = ""
		
		@headers.each do |header|
			header_str += "#{header[0]}: #{header[1]}\n"
		end
		
		header_str += "\n"
		self.reset_headers if @fcgi
		return header_str
	end
	
	def has_status_header?
		@headers.each do |header|
			return true if header[0] == "Status"
		end
		
		return false
	end
	
	def reset_connects
		@connects.clear if @connects.is_a?(Hash)
		@connects = {}
	end
	
	def reset_headers
		@headers = []
	end
	
	def header(key, value)
		@headers << [key, value]
	end
	
	def connect(signal, &block)
		@connects[signal] = [] if !@connects[signal]
		@connects[signal] << block
	end
	
	def printcont(tmp_out, args = {})
		if @fcgi
			@fcgi.print self.print_headers
			tmp_out.rewind
			@fcgi.print tmp_out.read.to_s
		else
			if args[:io] and !args[:custom_io]
				old_out = $stdout
				$stdout = args[:io]
			elsif !args[:custom_io]
				$stdout = STDOUT
			end
			
			if !args[:custom_io]
				print self.print_headers if !args.has_key?(:with_headers) or args[:with_headers]
				tmp_out.rewind
				print tmp_out.read
			end
		end
	end
	
	def load_return(filename, args = {})
		if !args[:io]
			retio = StringIO.new
			args[:io] = retio
		end
		
		@args = args
		self.load_filename(filename, args)
		
		if !args[:custom_io]
			retio.rewind
			return retio.read
		end
	end
	
	def load_filename(filename, args = {})
		begin
			if !args[:custom_io]
				tmp_out = StringIO.new
				$stdout = tmp_out
			end
			
			self.import(filename)
			
			if @connects["exit"]
				@connects["exit"].each do |block|
					block.call
				end
			end
			
			self.printcont(tmp_out, args)
		rescue SystemExit => e
			self.printcont(tmp_out, args)
		rescue Exception => e
			self.handle_error(e)
			self.printcont(tmp_out, args)
		end
	end
	
	def handle_error(e)
		begin
			if @connects and @connects.has_key?("error")
				@connects["error"].each do |block|
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
		
		e.backtrace.each do |line|
			print CGI.escapeHTML(line) + "\n"
		end
	end
end

class Knj::Eruby::Handler < Erubis::Eruby
	include Erubis::StdoutEnhancer
end