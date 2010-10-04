class ERuby
	def self.import(filename)
		filename = File.expand_path(filename)
		pwd = Dir.pwd
		Dir.chdir(File.dirname(filename))
		
		cachename = "#{KnjEruby.filepath}/cache/#{filename.gsub("/", "_").gsub(".", "_")}.cache"
		eruby = KnjEruby.load_file(File.basename(filename), {:cachename => cachename})
		print eruby.evaluate
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
	
	def self.printcont(tmp_out)
		if @fcgi
			@fcgi.print self.print_headers
			tmp_out.rewind
			@fcgi.print tmp_out.read.to_s
		else
			$stdout = STDOUT
			print self.print_headers
			tmp_out.rewind
			print tmp_out.read
		end
	end
	
	def self.load(filename)
		begin
			tmp_out = StringIO.new
			$stdout = tmp_out
			ERuby.import(filename)
			KnjEruby.printcont(tmp_out)
		rescue SystemExit => e
			KnjEruby.printcont(tmp_out)
			exit if !@fcgi
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
				KnjEruby.printcont(tmp_out)
			end
		end
	end
end