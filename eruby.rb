class Knj::Eruby
	attr_reader :fcgi
	attr_reader :connects, :headers
	
	def initialize(args = {})
		@args = args
		@settings_loaded = true
		@inseq_cache = false
		@inseq_rbc = false
		@java_compile = false
		@filepath = File.dirname(Knj::Os::realpath(__FILE__))
		@connects = {}
		
		if RUBY_PLATFORM == "java"
			@java_compile = true
			@java_factory = javax.script.ScriptEngineManager.new
			@java_engine = @java_factory.getEngineByName("jruby")
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
		pwd = Dir.pwd
		Dir.chdir(File.dirname(filename))
		
		fpath = "#{@filepath}/erb/cache/#{filename.gsub("/", "_").gsub(".", "_")}"
		pi = Knj::Php.pathinfo(filename)
		cachename = "#{fpath}.cache"
		
		filetime = File.mtime(filename)
		cacheexists = File.exists?(cachename)
		cachetime = File.mtime(cachename) if File.exists?(cachename)
		
		if !cacheexists or filetime > cachetime
			Knj::Eruby::Handler.load_file(File.basename(filename), {:cachename => cachename})
			cachetime = File.mtime(cachename)
			reload_cache = true
		end
		
		if @java_compile
			if !@eruby_java_cache[cachename] or reload_cache
				#@eruby_java_cache[cachename] = @java_engine.compile(File.read(cachename))
				@eruby_java_cache[cachename] = File.read(cachename)
			end
			
			#@eruby_java_cache[cachename].eval
			eval(@eruby_java_cache[cachename])
		elsif @inseq_cache
			if @inseq_rbc
				bytepath = pi["dirname"] + "/" + pi["basename"] + ".rbc"
				byteexists = File.exists?(bytepath)
				bytetime = File.mtime(bytepath) if File.exists?(bytepath)
				
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
				if !@eruby_rbyte[cachename] or reload_cache
					@eruby_rbyte[cachename] = RubyVM::InstructionSequence.new(File.read(cachename))
					#@eruby_rbyte[cachename] = RubyVM::InstructionSequence.compile_file(cachename)
					@eruby_rbyte[cachename].eval
				else
					_buf = ""
					@eruby_rbyte[cachename].eval
					if _buf
						print _buf
					end
				end
			end
		else
			Knj::Eruby::Handler.load_file(File.basename(filename), {:cachename => cachename})
			print Knj::Eruby::Handler.evaluate
		end
		
		Dir.chdir(pwd)
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
			if header[0] == "Status"
				return true
			end
		end
		
		return false
	end
	
	def reset_connects
		@connects = {}
	end
	
	def reset_headers
		@headers = [
			["Content-Type", "text/html; charset=utf-8"]
		]
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
		self.load(filename, args)
		
		if !args[:custom_io]
			retio.rewind
			return retio.read
		end
	end
	
	def load(filename, args = {})
		begin
			if !args[:custom_io]
				tmp_out = StringIO.new
				$stdout = tmp_out
			end
			
			self.import(filename)
			
			if self.connects["exit"]
				self.connects["exit"].each do |block|
					block.call
				end
			end
			
			self.printcont(tmp_out, args)
		rescue SystemExit => e
			self.printcont(tmp_out, args)
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
			
			e.backtrace.each do |line|
				print CGI.escapeHTML(line) + "\n"
			end
			
			self.printcont(tmp_out, args)
		end
	end
end

class Knj::Eruby::Handler < Erubis::Eruby
	include Erubis::StdoutEnhancer
end